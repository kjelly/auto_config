"""Ollama HTTP contracts, semantic cache, and gamepad PTY flows without a model.

Run: python3 tests/gamepad_ai_test.py
All requests go to a temporary loopback server; history and cache are isolated.
"""
import copy
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
import json
from pathlib import Path
import subprocess
import sys
import tempfile
import threading
import time
import unittest

import gamepad_test as core


class OllamaServer:
    def __init__(self):
        self.requests = []
        self.digest = 'embed-version-1'
        self.error = None
        self.delay = 0
        self.bad_vectors = False
        self.reply = {'summary': '用途說明', 'parameters': ['參數說明'],
                      'side_effects': ['會寫入檔案'], 'candidates': [
                          {'label': '建議命令', 'command': 'print AI_CANDIDATE',
                           'explanation': '候選說明', 'shell': 'nushell'}]}
        fixture = self

        class Handler(BaseHTTPRequestHandler):
            def log_message(self, *_):
                pass

            def do_GET(self):
                fixture.requests.append((self.path, None))
                self.respond({'models': [
                    {'name': 'chat-test', 'digest': 'chat-version-1'},
                    {'name': 'embed-test', 'digest': fixture.digest},
                    {'name': 'remote:cloud', 'digest': 'cloud-version'},
                ]})

            def do_POST(self):
                data = json.loads(self.rfile.read(int(self.headers['Content-Length'])))
                fixture.requests.append((self.path, data))
                if fixture.delay:
                    time.sleep(fixture.delay)
                if fixture.error:
                    self.respond({'error': fixture.error}, 500)
                elif self.path == '/api/show':
                    self.respond({'capabilities': ['embedding' if data['model'] == 'embed-test' else 'completion'],
                                  'remote_model': 'remote' if ':cloud' in data['model'] else ''})
                elif self.path == '/api/chat':
                    reply = copy.deepcopy(fixture.reply)
                    if data.get('messages') and json.loads(data['messages'][1]['content'])['operation'] == 'explain':
                        reply['candidates'] = []
                    self.respond({'done': True, 'message': {'content': json.dumps(reply, ensure_ascii=False)}})
                elif self.path == '/api/embed':
                    def vector(text):
                        if any(word in text for word in ('連接埠', 'ss ', 'port')):
                            return [2, 0, 0]
                        if 'go' in text:
                            return [0, 3, 0]
                        return [0, 0, 4]
                    self.respond({'embeddings': [[0, 0, 0]] if fixture.bad_vectors else [vector(t) for t in data['input']]})
                else:
                    self.respond({'error': 'unknown endpoint'}, 404)

            def respond(self, data, status=200):
                body = json.dumps(data, ensure_ascii=False).encode()
                self.send_response(status)
                self.send_header('Content-Type', 'application/json')
                self.send_header('Content-Length', str(len(body)))
                self.end_headers()
                try:
                    self.wfile.write(body)
                except (BrokenPipeError, ConnectionResetError):
                    pass

        self.server = ThreadingHTTPServer(('127.0.0.1', 0), Handler)
        self.url = f'http://127.0.0.1:{self.server.server_port}'
        self.thread = threading.Thread(target=self.server.serve_forever, daemon=True)
        self.thread.start()

    def close(self):
        self.server.shutdown()
        self.server.server_close()
        self.thread.join()


class ApiTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix='gamepad-ai-')
        self.addCleanup(self.temp.cleanup)
        self.base = Path(self.temp.name)
        self.cache = self.base / 'private' / 'history.json'
        self.server = OllamaServer()
        self.addCleanup(self.server.close)

    def run_nu(self, code, *, success=True):
        script = '\n'.join([
            f'source {core.literal(core.SOURCE)}',
            f'$env.GAMEPAD_OLLAMA_HOST = {core.literal(self.server.url)}',
            f'$env.GAMEPAD_AI_CACHE_FILE = {core.literal(self.cache)}',
            '$env.GAMEPAD_OLLAMA_TIMEOUT = 2sec',
            '$env.GAMEPAD_AI_HISTORY_LIMIT = 200', code,
        ])
        result = subprocess.run([core.NU, '-n', '-c', script], text=True, capture_output=True, cwd=self.base)
        self.assertEqual(result.returncode == 0, success, result.stdout + result.stderr)
        return json.loads(result.stdout) if success else result.stderr

    def test_chat_sends_schema_and_never_runs_candidate(self):
        marker = self.base / 'not-run'
        self.server.reply['candidates'][0]['command'] = f'"x" | save {core.literal(marker)}'
        result = self.run_nu('menu ai chat {name: chat-test} generate "找出最近七天的大檔案" | to json')
        self.assertEqual(result, self.server.reply)
        self.assertFalse(marker.exists())
        endpoint, body = self.server.requests[-1]
        self.assertEqual(endpoint, '/api/chat')
        self.assertFalse(body['stream'])
        self.assertEqual(body['format']['properties']['candidates']['maxItems'], 3)
        self.assertEqual(json.loads(body['messages'][1]['content'])['text'], '找出最近七天的大檔案')

    def test_explain_rewrite_and_error_operation_context(self):
        for operation in ('explain', 'rewrite', 'error'):
            reply = self.run_nu(f'menu ai chat {{name: chat-test}} {operation} "input" "instruction" | to json')
            self.assertEqual(reply['summary'], '用途說明')
            request = json.loads(self.server.requests[-1][1]['messages'][1]['content'])
            self.assertEqual(request['operation'], operation)
            self.assertEqual(request['instruction'], 'instruction')

    def test_invalid_schema_shell_syntax_and_control_characters_are_rejected(self):
        original = copy.deepcopy(self.server.reply)
        for field, value in [('shell', 'bash'),
                             ('command', 'print \x1b[31m'), ('command', '')]:
            self.server.reply = copy.deepcopy(original)
            self.server.reply['candidates'][0][field] = value
            self.run_nu('menu ai chat {name: chat-test} generate test', success=False)
        self.server.reply = {'summary': 'missing fields'}
        self.run_nu('menu ai chat {name: chat-test} generate test', success=False)

    def test_invalid_syntax_does_not_hide_valid_candidates(self):
        self.server.reply['candidates'].append({
            'label': 'invalid', 'command': 'ls | where {', 'explanation': 'bad syntax', 'shell': 'nushell'})
        reply = self.run_nu('menu ai chat {name: chat-test} generate test | to json')
        self.assertEqual([candidate['command'] for candidate in reply['candidates']], ['print AI_CANDIDATE'])
        self.assertIn('已略過 1 筆', reply['side_effects'][-1])

    def test_model_selection_validates_capability_and_excludes_cloud(self):
        result = self.run_nu('$env.GAMEPAD_OLLAMA_MODEL = "chat-test"; menu ai model | to json')
        self.assertEqual(result['model']['name'], 'chat-test')
        self.run_nu('$env.GAMEPAD_OLLAMA_MODEL = "embed-test"; menu ai model', success=False)
        self.run_nu('$env.GAMEPAD_OLLAMA_MODEL = "remote:cloud"; menu ai model', success=False)
        self.run_nu('$env.GAMEPAD_OLLAMA_MODEL = "missing"; menu ai model', success=False)

    def test_api_failure_timeout_and_input_limit(self):
        self.server.error = 'model not found'
        self.assertIn('model not found', self.run_nu('menu ai request chat {model: missing}', success=False))
        self.server.error = None
        self.server.delay = 0.15
        self.assertIn('逾時', self.run_nu('$env.GAMEPAD_OLLAMA_TIMEOUT = 10ms; menu ai request chat {model: test}', success=False))
        before = len(self.server.requests)
        self.run_nu('menu ai chat {name: chat-test} generate ("x" | fill --width 16001 --character x)', success=False)
        self.assertEqual(len(self.server.requests), before)

    def semantic(self, *, digest='embed-version-1'):
        return self.run_nu(f'menu ai semantic {{name: embed-test, digest: {digest}}} "之前查連接埠的指令" [{{command: "go build ./..."}} {{command: "ss -ltnp"}}] | to json')

    def test_semantic_rank_cache_reuse_and_permissions(self):
        result = self.semantic()
        self.assertEqual(result[0]['command'], 'ss -ltnp')
        embeds = [body for endpoint, body in self.server.requests if endpoint == '/api/embed']
        self.assertEqual(len(embeds), 2)
        self.assertFalse(embeds[0]['truncate'])
        cache = json.loads(self.cache.read_text())
        self.assertNotIn('ss -ltnp', self.cache.read_text())
        self.assertEqual(len(cache['entries']), 2)
        self.assertEqual(self.cache.stat().st_mode & 0o777, 0o600)
        self.assertEqual(self.cache.parent.stat().st_mode & 0o777, 0o700)
        self.semantic()
        self.assertEqual(len([r for r in self.server.requests if r[0] == '/api/embed']), 3)

    def test_semantic_cache_invalidates_model_digest_host_and_corruption(self):
        self.semantic()
        self.semantic(digest='new-version')
        self.assertEqual(len([r for r in self.server.requests if r[0] == '/api/embed']), 4)
        cache = json.loads(self.cache.read_text())
        cache['identity']['host'] = 'http://other-server'
        self.cache.write_text(json.dumps(cache))
        self.semantic(digest='new-version')
        self.assertEqual(len([r for r in self.server.requests if r[0] == '/api/embed']), 6)
        self.cache.write_text('broken json')
        self.semantic()
        self.assertEqual(len([r for r in self.server.requests if r[0] == '/api/embed']), 8)

    def test_semantic_bad_vectors_and_empty_history(self):
        self.assertEqual(self.run_nu('menu ai semantic {name: embed-test, digest: v1} query [] | to json'), [])
        self.assertEqual(self.server.requests, [])
        self.server.bad_vectors = True
        self.run_nu('menu ai semantic {name: embed-test, digest: v1} query [{command: test}]', success=False)
        self.assertFalse(self.cache.exists())


class AiMenuTests(unittest.TestCase):
    tearDown = core.ControllerTests.tearDown
    read = core.ControllerTests.read
    send = core.ControllerTests.send
    state = core.ControllerTests.state
    choose = core.ControllerTests.choose
    wait_for_json = core.ControllerTests.wait_for_json

    def setUp(self):
        core.ControllerTests.setUp(self)
        self.server = OllamaServer()
        self.addCleanup(self.server.close)
        self.send(f'$env.GAMEPAD_OLLAMA_HOST = {core.literal(self.server.url)}; '
                  '$env.GAMEPAD_OLLAMA_MODEL = "chat-test"; $env.GAMEPAD_OLLAMA_EMBED_MODEL = "embed-test"; '
                  f'$env.GAMEPAD_AI_CACHE_FILE = {core.literal(self.base / "cache/history.json")}\r')
        if 'native' in self._testMethodName:
            self.send('$env.PATH = []\r')
        self.output = b''

    def ai_menu(self):
        self.send(core.ESC)
        self.choose(17)
        self.assertIn('AI 助手（Ollama）'.encode(), self.output[-7000:])

    def test_generate_from_main_menu_stages_only_after_review_and_supports_undo(self):
        marker = self.base / 'must-not-run'
        command = f'"value" | save {core.literal(marker)}'
        self.server.reply['candidates'][0]['command'] = command
        self.send('找出最近七天的大檔案')
        self.ai_menu()
        self.choose(1)  # Generate.
        self.choose(1)  # Current command line as the request.
        self.choose(1)  # Candidate after report item.
        self.choose()  # Stage after preview.
        self.assertEqual(self.state()['buffer'], command)
        self.assertFalse(marker.exists())
        self.send(core.ESC)
        self.choose(16)  # Management.
        self.choose(3)  # Undo.
        self.assertEqual(self.state()['buffer'], '找出最近七天的大檔案')

    def test_explain_native_shows_parameters_effects_and_preserves_cursor(self):
        self.send('print original')
        self.send(core.LEFT)
        before = self.state()
        self.ai_menu()
        self.choose()  # Explain.
        self.choose()  # Report.
        self.assertIn('參數說明'.encode(), self.output[-9000:])
        self.assertIn('會寫入檔案'.encode(), self.output[-9000:])
        self.send(core.ESC, 0.35)
        self.assertEqual(self.state(), before)

    def test_rewrite_typed_instruction_and_cancel_preserve_original(self):
        self.send('echo original')
        before = self.state()
        self.ai_menu()
        self.choose(2)
        self.send('改成 Nushell\r', 0.5)
        self.assertEqual(json.loads(self.server.requests[-1][1]['messages'][1]['content'])['instruction'], '改成 Nushell')
        self.send(core.ESC, 0.35)
        self.assertEqual(self.state(), before)

    def test_error_from_clipboard_preserves_text_without_evaluating_it(self):
        marker = self.base / 'not-run'
        text = f'ERROR: $(touch {marker})\nmissing input\n'
        bindir = self.base / 'clipboard-bin'
        bindir.mkdir()
        paste = bindir / 'wl-paste'
        paste.write_text(f'#!{sys.executable}\nimport sys\nsys.stdout.write({text!r})\n')
        paste.chmod(0o755)
        self.send(f'$env.PATH = ($env.PATH | prepend {core.literal(bindir)}); $env.WAYLAND_DISPLAY = "fixture"\r')
        self.ai_menu()
        self.choose(3)
        self.choose()  # Clipboard.
        request = json.loads(self.server.requests[-1][1]['messages'][1]['content'])
        self.assertEqual(request['text'], text)
        self.assertFalse(marker.exists())
        self.send(core.ESC, 0.35)
        self.assertEqual(self.state()['buffer'], '')

    def test_opening_ai_menu_is_offline_and_ctrl_c_cancels_http_request(self):
        self.send('print preserve')
        before = self.state()
        self.ai_menu()
        self.assertEqual(self.server.requests, [])
        self.server.delay = 2
        self.choose()  # Explain waits for model metadata.
        self.send(b'\x03', 0.5)
        self.assertEqual(self.state(), before)

    def test_error_from_archived_task_output_without_tmux_or_execution(self):
        resultfile = self.base / 'task.result.json'
        resultfile.write_text(json.dumps({'token': 'owned', 'output': 'BUILD_ERROR: missing dependency'}))
        task = {'token': 'owned', 'command': 'go build ./...', 'file': str(resultfile).removesuffix('.result.json')}
        self.send(f'$env.GAMEPAD_TASKS = [{json.dumps(task)}]\r')
        self.ai_menu()
        self.choose(3)
        self.choose(1)  # Archived task after clipboard option.
        request = json.loads(self.server.requests[-1][1]['messages'][1]['content'])
        self.assertEqual(request['operation'], 'error')
        self.assertIn('BUILD_ERROR', request['text'])
        self.assertIn('go build', request['instruction'])
        self.send(core.ESC, 0.35)
        self.assertEqual(self.state()['buffer'], '')

    def test_semantic_history_native_stages_original_history_command(self):
        import sqlite3
        with sqlite3.connect(self.historydb) as db:
            db.execute('INSERT INTO history (command_line, cwd, exit_status) VALUES (?, ?, 0)', ('ss -ltnp', str(self.cwd)))
        self.send('之前查連接埠的指令')
        self.ai_menu()
        self.choose(4)
        self.choose(1)  # Current command line.
        self.choose()  # Current directory scope.
        self.choose()  # Best semantic result.
        self.choose()  # Stage.
        self.assertEqual(self.state()['buffer'], 'ss -ltnp')

    def test_model_selection_native_and_network_failure_is_recoverable(self):
        self.ai_menu()
        self.choose(5)  # Select chat model.
        self.assertIn('選擇本機對話模型'.encode(), self.output[-6000:])
        self.choose()
        self.assertIn('AI 助手（Ollama）'.encode(), self.output[-6000:])
        self.server.error = 'unavailable'
        self.choose(5)
        self.assertIn('unavailable'.encode(), self.output[-6000:])
        self.send(core.ESC, 0.35)
        self.assertEqual(self.state()['buffer'], '')


if __name__ == '__main__':
    unittest.main(verbosity=2)

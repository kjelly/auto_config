"""Isolated fixtures only: never source custom.nu, a real profile or user history."""
import json
import os
from pathlib import Path
import shutil
import sqlite3
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]
NU = shutil.which('nu')


def q(value):
    return json.dumps(str(value), ensure_ascii=False)


class ShellConfigTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix='nu-shell-config-')
        self.base = Path(self.temp.name)
        self.bin = self.base / 'bin'
        self.bin.mkdir()
        self.env = dict(os.environ, TEST_BASE=str(self.base))

    def tearDown(self):
        self.temp.cleanup()

    def stub(self, name, source):
        p = self.bin / name
        p.write_text('#!/usr/bin/env python3\n' + source)
        p.chmod(0o755)
        return p

    def nu(self, code, module='shell-integration.nu', check=True):
        prefix = f'source {q(ROOT / "scripts" / module)}; $env.PATH = ($env.PATH | prepend {q(self.bin)}); '
        r = subprocess.run([NU, '-n', '-c', prefix + code], cwd=self.base,
                           env=self.env, text=True, capture_output=True)
        if check:
            self.assertEqual(r.returncode, 0, r.stderr)
            return json.loads(r.stdout)
        return r

    def test_theme_numeric_width_and_hints_key(self):
        actual = self.nu('def "term size" [] { {columns: 100 rows: 32} }; $env.EINK_WIDTH = "100"; update-nushell-theme; $env.config.color_config.hints | to json')
        self.assertEqual(actual, 'dark_gray_bold')

    def test_task_worker_skips_interactive_theme_and_tmux_refresh(self):
        tmux_called = self.base / 'tmux-called'
        term_called = self.base / 'term-called'
        self.stub('tmux', 'from pathlib import Path\nPath(' + repr(str(tmux_called)) + ').touch()\n')
        actual = self.nu('def "term size" [] { "called" | save -f ' + q(term_called) + '; {columns: 100, rows: 32} }; '
                         '$env.GAMEPAD_TASK_RUNNING = "1"; $env.TMUX = "fixture"; '
                         'refresh-eink-env; update-nushell-theme; {state: $env.NU_THEME_STATE?, queried: ('
                         + q(term_called) + ' | path exists)} | to json')
        self.assertIsNone(actual['state'])
        self.assertFalse(tmux_called.exists())
        # Nu may query terminal width while rendering the final CLI result;
        # record the spy before that render, immediately after the two helpers.
        self.assertFalse(actual['queried'])

    def test_theme_cache_and_env_change(self):
        result = self.nu('def "term size" [] { {columns: 100 rows: 32} }; $env.EINK_WIDTH = "100"; update-nushell-theme; $env.config.color_config.hints = "cache-marker"; update-nushell-theme; let cached = $env.config.color_config.hints; $env.EINK_WIDTH = "80"; update-nushell-theme; [$cached $env.config.color_config.hints] | to json')
        self.assertEqual(result, ['cache-marker', 'cyan'])

    def test_output_theme_does_not_launch_tmux(self):
        self.stub('tmux', 'raise SystemExit("must not launch tmux")\n')
        actual = self.nu('$env.TMUX = "fixture"; update-nushell-theme; update-nushell-theme; true | to json')
        self.assertTrue(actual)

    def test_tmux_width_refresh_and_unset(self):
        self.stub('tmux', 'print("EINK_WIDTH=100")\n')
        result = self.nu('$env.TMUX = "fixture"; refresh-eink-env; $env.EINK_WIDTH | to json')
        self.assertEqual(result, 100)
        self.stub('tmux', 'raise SystemExit(1)\n')
        result = self.nu('$env.TMUX = "fixture"; $env.EINK_WIDTH = 100; refresh-eink-env; $env.EINK_WIDTH | to json')
        self.assertEqual(result, 0)

    def test_completer_preserves_expanded_command_and_quoted_arguments(self):
        self.stub('carapace', 'import sys, json\nprint(json.dumps([{"value": "ok", "description": json.dumps(sys.argv[1:])}]))\n')
        result = self.nu('shell-complete {command: [git --no-pager log "a b"]} | to json')
        self.assertEqual(json.loads(result[0]['description']), ['git', 'nushell', 'git', '--no-pager', 'log', 'a b'])

    def test_completer_falls_back_on_errors_empty_and_invalid_data(self):
        for body in ['raise SystemExit(7)', 'print("invalid")', 'print("[]")', 'print("{}")', 'print("null")', 'print("[42]")', 'import json; print(json.dumps([dict(other="bad")]))']:
            with self.subTest(body=body):
                self.stub('carapace', body + '\n')
                self.assertIsNone(self.nu('shell-complete {command: [test ""]} | to json'))

    def test_completer_missing_binary_falls_back(self):
        self.assertIsNone(self.nu('$env.PATH = []; shell-complete {command: [test ""]} | to json'))

    def test_prompt_preserves_status_and_duration(self):
        self.stub('starship', 'import json, sys\nprint(json.dumps(sys.argv[1:]))\n')
        result = self.nu('$env.LAST_EXIT_CODE = 42; $env.CMD_DURATION_MS = 1234; my-prompt | to json')
        self.assertEqual(json.loads(result), ['prompt', '--status=42', '--cmd-duration', '1234'])

    def test_prompt_missing_binary_has_native_fallback(self):
        result = self.nu('$env.PATH = []; my-prompt | to json')
        self.assertEqual(result, str(self.base) + ' ')

    def test_direnv_path_removals_and_invalid_json(self):
        self.stub('direnv', 'import json\nprint(json.dumps({"PATH": "/one:/two", "TEST_REMOVE": None, "TEST_VALUE": "line1\\nline2", "PWD": "/bad"}))\n')
        result = self.nu('$env.TEST_REMOVE = "old"; shell-directory-env; {path: $env.PATH, removed: $env.TEST_REMOVE?, value: $env.TEST_VALUE?, pwd: $env.PWD} | to json')
        self.assertEqual(result, {'path': ['/one', '/two'], 'removed': None, 'value': 'line1\nline2', 'pwd': str(self.base)})
        for body in ['print("invalid")', 'print("null")', 'print("[]")', 'raise SystemExit(1)']:
            self.stub('direnv', body + '\n')
            self.assertEqual(self.nu('$env.TEST_VALUE = "preserve"; shell-directory-env; $env.TEST_VALUE | to json'), 'preserve')

    def test_profile_import_is_login_only_and_preserves_multiline(self):
        profile = self.base / '.profile'
        profile.write_text('export TEST_PROFILE="first\nsecond=third"\nexport PATH="/a:/b"\nprintf noisy-output\n')
        code = f'$env.HOME = {q(self.base)}; source {q(ROOT / "scripts/login-env.nu")}; {{value: $env.TEST_PROFILE, path: $env.PATH}} | to json'
        result = self.nu(code)
        self.assertEqual(result, {'value': 'first\nsecond=third', 'path': ['/a', '/b']})
        # The interactive config must not execute the POSIX profile at startup.
        config = (ROOT / 'config.nu').read_text()
        self.assertNotRegex(config, r'(?m)^bash -c')
        self.assertNotIn('source scripts/login-env.nu', config)

    def test_failed_profile_does_not_import_partial_environment(self):
        (self.base / '.profile').write_text('export TEST_PARTIAL=bad\nfalse\n')
        result = self.nu(f'$env.HOME = {q(self.base)}; source {q(ROOT / "scripts/login-env.nu")}; $env.TEST_PARTIAL? | to json')
        self.assertIsNone(result)

    def database(self):
        p = self.base / 'history.sqlite3'
        with sqlite3.connect(p) as db:
            db.execute('CREATE TABLE history (id INTEGER PRIMARY KEY, command_line TEXT, cwd TEXT, exit_status INTEGER)')
            db.executemany('INSERT INTO history VALUES (?, ?, ?, ?)', [
                (1, 'git log', str(self.base), 0),
                (2, 'git bad', str(self.base), 1),
                (3, 'git log', '/elsewhere', 0),
                (4, 'git unknown', str(self.base), None),
                (5, 'git child', str(self.base / 'child'), 0),
                (6, 'git sibling', str(self.base) + '-sibling', 0),
                (7, '  literal %_\\quoted\' text', str(self.base), 0),
                (8, '\u2003git unicode', str(self.base), 0),
                (9, 'print FIRST\nprint SECOND', str(self.base), 0),
            ])
        return p

    def rows(self, flags):
        p = self.database()
        return self.nu(f'$env.NU_HISTORY_DATABASE = {q(p)}; shell history-rows {flags} | to json', 'history-query.nu')

    def test_history_sql_scope_status_and_recency_order(self):
        rows = self.rows('--here --status failed')
        self.assertEqual([x['command'] for x in rows], ['git bad'])

    def test_history_sql_project_excludes_siblings(self):
        rows = self.rows(f'--project {q(self.base)}')
        self.assertEqual([x['command'] for x in rows], ['git log', 'git bad', 'git unknown', 'git child', '  literal %_\\quoted\' text', '\u2003git unicode', 'print FIRST\nprint SECOND'])

    def test_history_sql_prefix_is_literal_and_unicode_trim_matches(self):
        p = self.database()
        for prefix, commands in [("literal %_\\quoted'", ["  literal %_\\quoted' text"]), ('git ', ['git log', 'git bad', 'git log', 'git unknown', 'git child', 'git sibling', '\u2003git unicode']), ("' OR 1=1 --", [])]:
            with self.subTest(prefix=prefix):
                result = self.nu(f'$env.NU_HISTORY_DATABASE = {q(p)}; shell history-rows --prefix {q(prefix)} | get command | to json', 'history-query.nu')
                self.assertEqual(result, commands)

    def test_history_missing_or_bad_database_uses_native_fallback(self):
        p = self.base / 'bad.sqlite3'
        for exists in (False, True):
            if exists:
                p.write_text('not a database')
            code = f'def history [--long] {{ [{{command: "native"}}] }}; source {q(ROOT / "scripts/history-query.nu")}; $env.NU_HISTORY_DATABASE = {q(p)}; shell history-rows | to json'
            r = subprocess.run([NU, '-n', '-c', code], text=True, capture_output=True)
            self.assertEqual(r.returncode, 0, r.stderr)
            self.assertEqual(json.loads(r.stdout), [{'command': 'native'}])

    def secure_stubs(self, fail=''):
        self.env['TEST_FAIL'] = fail
        self.stub('age', '''import os, sys
from pathlib import Path
args = sys.argv[1:]
out = Path(args[args.index('--output') + 1])
if '--decrypt' in args:
    out.write_text('plaintext fixture')
    out.chmod(0o600)
    if os.environ.get('TEST_FAIL') == 'decrypt': raise SystemExit(3)
else:
    out.write_text('NEW ENCRYPTED FIXTURE')
    if os.environ.get('TEST_FAIL') == 'encrypt': raise SystemExit(4)
''')
        self.stub('nvim', '''import json, os, sys
from pathlib import Path
p = Path(sys.argv[-1])
Path(os.environ['TEST_BASE'], 'editor.json').write_text(json.dumps({'path': str(p), 'mode': p.stat().st_mode & 0o777, 'parent_mode': p.parent.stat().st_mode & 0o777}))
if os.environ.get('TEST_FAIL') == 'editor': raise SystemExit(5)
p.write_text('edited fixture')
''')

    def test_age_edit_atomic_success_permissions_and_cleanup(self):
        self.secure_stubs()
        target = self.base / 'encrypted file.age'
        target.write_text('ORIGINAL')
        target.chmod(0o640)
        self.nu(f'age-edit {q(target)}; true | to json', 'secure-edit.nu')
        self.assertEqual(target.read_text(), 'NEW ENCRYPTED FIXTURE')
        self.assertEqual(target.stat().st_mode & 0o777, 0o640)
        editor = json.loads((self.base / 'editor.json').read_text())
        self.assertEqual(editor['mode'], 0o600)
        self.assertEqual(editor['parent_mode'], 0o700)
        self.assertFalse(Path(editor['path']).exists())
        self.assertFalse(list(self.base.glob('.age-edit.*')))

    def test_age_edit_each_failure_preserves_original_and_cleans(self):
        for fail in ('decrypt', 'editor', 'encrypt'):
            with self.subTest(stage=fail):
                self.secure_stubs(fail)
                target = self.base / 'encrypted.age'
                target.write_text('ORIGINAL')
                result = self.nu(f'age-edit {q(target)}', 'secure-edit.nu', check=False)
                self.assertNotEqual(result.returncode, 0)
                self.assertEqual(target.read_text(), 'ORIGINAL')
                self.assertFalse(list(self.base.glob('.age-edit.*')))
                if (self.base / 'editor.json').exists():
                    self.assertFalse(Path(json.loads((self.base / 'editor.json').read_text())['path']).exists())

    def test_sops_key_precedence(self):
        self.stub('age-keygen', 'print("age1fixture")\n')
        self.stub('sops', 'import json, os, sys\nprint(json.dumps({"key": os.environ["SOPS_AGE_KEY_FILE"], "args": sys.argv[1:]}))\n')
        for explicit in (False, True):
            expr = f'$env.SOPS_AGE_KEY_FILE = {q(self.base / "env-key")}; sops-age file.age' + (f' --key {q(self.base / "explicit-key")}' if explicit else '')
            result = self.nu(expr, 'secure-edit.nu')
            self.assertEqual(result['key'], str(self.base / ('explicit-key' if explicit else 'env-key')))
            self.assertEqual(result['args'], ['edit', '--age', 'age1fixture', '--', 'file.age'])


if __name__ == '__main__':
    unittest.main()

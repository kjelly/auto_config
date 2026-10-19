"""Real tmux lifecycle tests; private server, config, environment and processes."""
import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import time
import unittest

from gamepad_test import NU, ROOT, SOURCE, literal


@unittest.skipUnless(os.environ.get('GAMEPAD_TEST_REAL_TMUX') and shutil.which('tmux'),
                     'requires private local tmux socket permission')
class TaskTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix='gamepad-tasks-')
        self.base = Path(self.temp.name)
        self.cwd = self.base / "work 'quoted' $(literal) 中文"
        self.cwd.mkdir()
        self.config = self.base / 'config.nu'
        self.config.write_text('$env.config.show_banner = false\nalias task-fixture-alias = print ALIAS_OK\n')
        self.env_config = self.base / 'env.nu'
        self.env_config.write_text('')
        self.state = self.base / 'tasks.json'
        self.state.write_text('[]')
        self.result = self.base / 'result.json'
        self.env = dict(os.environ, TMUX_TMPDIR=str(self.base), TMPDIR=str(self.base),
                        BASH_ENV='/dev/null', GAMEPAD_TASK_MARKER='inherited value 中文')
        self.env.pop('TMUX', None)
        self.env.pop('TMUX_PANE', None)

    def tearDown(self):
        subprocess.run(['tmux', 'kill-server'], env=self.env, capture_output=True)
        self.temp.cleanup()

    def tmux(self, *args):
        result = subprocess.run(['tmux', *args], env=self.env, text=True, capture_output=True)
        self.assertEqual(result.returncode, 0, result.stderr)
        return result.stdout.strip()

    def nu(self, expression, *, check=True, extra_env=None):
        code = '\n'.join([
            f'source {literal(SOURCE)}',
            f'$env.GAMEPAD_TASK_CONFIG = {literal(self.config)}',
            f'$env.GAMEPAD_TASK_ENV_CONFIG = {literal(self.env_config)}',
            f'$env.GAMEPAD_TASKS = (open {literal(self.state)})',
            f'let result = (do --env {{ {expression} }})',
            f'$env.GAMEPAD_TASKS | to json | save -f {literal(self.state)}',
            f'$result | to json | save -f {literal(self.result)}',
        ])
        result = subprocess.run([NU, '-n', '--no-history', '-c', code], cwd=self.cwd,
                                env=dict(self.env, **(extra_env or {})), text=True, capture_output=True)
        if check:
            self.assertEqual(result.returncode, 0, result.stderr)
            return json.loads(self.result.read_text())
        return result

    def start(self, script, **kwargs):
        self.nu(f'menu task-start {literal(script)}; null', **kwargs)
        tasks = json.loads(self.state.read_text())
        self.assertTrue(tasks)
        return tasks[-1]

    def wait_done(self, task):
        deadline = time.monotonic() + 6
        while time.monotonic() < deadline:
            result = Path(task['file'] + '.result.json')
            if result.exists():
                state = subprocess.run(['tmux', '-S', task['socket'], 'display-message', '-p',
                                        '-t', task['pane'], '#{@gamepad_task}'],
                                       env=self.env, text=True, capture_output=True)
                if state.returncode != 0 or state.stdout.strip() != task['token']:
                    return
            time.sleep(0.05)
        output = subprocess.run(['tmux', '-S', task['socket'], 'capture-pane', '-p', '-t', task['pane']],
                                env=self.env, text=True, capture_output=True)
        self.fail('Task did not archive and close: ' + output.stdout + output.stderr)

    def test_short_task_retains_output_exit_status_cwd_and_environment(self):
        witness = self.base / 'witness.json'
        task = self.start('{pwd: $env.PWD, marker: $env.GAMEPAD_TASK_MARKER} | to json | save '
                          + literal(witness) + '; print TASK_OUTPUT; exit 7')
        self.wait_done(task)
        self.assertEqual(json.loads(witness.read_text()),
                         {'pwd': str(self.cwd), 'marker': 'inherited value 中文'})
        status = self.nu(f'menu task-status (menu task-find {literal(task["token"])})')
        self.assertEqual(status, {'owned': True, 'running': False, 'label': '已結束，狀態 7'})
        self.assertIn('TASK_OUTPUT', self.nu(f'menu task-output (menu task-find {literal(task["token"])})'))
        self.assertEqual(Path(task['directory']).stat().st_mode & 0o777, 0o700)
        self.assertEqual(Path(task['file']).stat().st_mode & 0o777, 0o600)
        self.assertEqual(Path(task['file'] + '.result.json').stat().st_mode & 0o777, 0o600)

    def test_config_alias_and_multiline_bash_are_available(self):
        task = self.start("task-fixture-alias\n^bash --noprofile --norc -c 'printf \"%s\\n\" \\\n  \"BASH MULTILINE\"'")
        self.wait_done(task)
        output = self.nu(f'menu task-output (menu task-find {literal(task["token"])})')
        self.assertIn('ALIAS_OK', output)
        self.assertIn('BASH MULTILINE', output)

    def test_interrupt_closes_pane_and_rerun_creates_a_new_owned_pane(self):
        task = self.start('print READY_TO_INTERRUPT; loop { sleep 100ms }')
        token = literal(task['token'])
        deadline = time.monotonic() + 4
        while time.monotonic() < deadline:
            if 'READY_TO_INTERRUPT' in self.tmux('capture-pane', '-p', '-t', task['pane']):
                break
            time.sleep(0.05)
        else:
            self.fail('Task never reached its loop')
        self.assertNotEqual(self.nu(f'menu task-rerun {token}', check=False).returncode, 0)
        self.nu(f'menu task-stop {token}; null')
        self.wait_done(task)
        self.assertEqual(self.nu(f'menu task-status (menu task-find {token})')['label'], '已中止，狀態 130')
        self.nu(f'menu task-rerun {token}; null')
        task = json.loads(self.state.read_text())[-1]
        self.assertEqual(self.tmux('display-message', '-p', '-t', task['pane'], '#{pane_dead}'), '0')
        self.nu(f'menu task-stop {token}; null')
        self.wait_done(task)

    def test_ownership_mismatch_rejects_stop_rerun_and_output(self):
        task = self.start('print ORIGINAL; loop { sleep 100ms }')
        self.tmux('set-option', '-p', '-t', task['pane'], '@gamepad_task', 'someone-else')
        for operation in ['stop', 'rerun']:
            result = self.nu(f'menu task-{operation} {literal(task["token"])}', check=False)
            self.assertNotEqual(result.returncode, 0)
            self.assertIn('所有權', result.stderr)
        result = self.nu('menu task-output ($env.GAMEPAD_TASKS | first)', check=False)
        self.assertNotEqual(result.returncode, 0)
        self.assertEqual(self.tmux('display-message', '-p', '-t', task['pane'], '#{@gamepad_task}'), 'someone-else')

    def test_close_removes_only_owned_finished_pane_and_snapshot(self):
        task = self.start('print DONE')
        self.wait_done(task)
        self.nu(f'menu task-close {literal(task["token"])}; null')
        self.assertEqual(json.loads(self.state.read_text()), [])
        self.assertFalse(Path(task['directory']).exists())

    def test_inside_tmux_keeps_control_pane_and_targets_new_pane(self):
        control = self.tmux('new-session', '-d', '-P', '-F', '#{pane_id}', '-s', 'control', '-x', '100', '-y', '32', 'sleep 120')
        socket = self.tmux('display-message', '-p', '#{socket_path}')
        pid = self.tmux('display-message', '-p', '#{pid}')
        task = self.start('print CHILD_TASK', extra_env={'TMUX': f'{socket},{pid},0', 'TMUX_PANE': control})
        self.wait_done(task)
        self.assertNotEqual(task['pane'], control)
        self.assertEqual(self.tmux('display-message', '-p', '-t', control, '#{pane_dead}'), '0')
        self.assertEqual(self.tmux('display-message', '-p', '-t', control, '#{pane_active}'), '1')

    def test_tmux_clipboard_fallback_preserves_exact_multiline_text(self):
        self.tmux('new-session', '-d', '-s', 'clipboard', 'sleep 120')
        socket = self.tmux('display-message', '-p', '#{socket_path}')
        pid = self.tmux('display-message', '-p', '#{pid}')
        text = '中文 "quoted" \\literal\nsecond line\n\n'
        result = self.nu('let written = (menu clipboard-write ' + literal(text)
                         + '); {written: $written, read: (menu clipboard-read)}',
                         extra_env={'TMUX': f'{socket},{pid},0', 'WAYLAND_DISPLAY': '', 'DISPLAY': ''})
        self.assertTrue(result['written']['ok'])
        self.assertEqual(result['read'], {'ok': True, 'backend': 'tmux', 'text': text})

    def test_interrupt_during_config_load_closes_pane_and_does_not_start_command(self):
        ready = self.base / 'config-starting'
        ran = self.base / 'command-must-not-run'
        self.config.write_text(f'source {literal(ROOT / "scripts/shell-integration.nu")}\n'
                               f'"ready" | save -f {literal(ready)}\n^sleep 120\nupdate-nushell-theme\n')
        task = self.start(f'"unexpected" | save {literal(ran)}')
        deadline = time.monotonic() + 4
        while not ready.exists() and time.monotonic() < deadline:
            time.sleep(0.03)
        self.assertTrue(ready.exists())
        self.nu(f'menu task-stop {literal(task["token"])}; null')
        self.wait_done(task)
        self.assertFalse(ran.exists())
        result = json.loads(Path(task['file'] + '.result.json').read_text())
        self.assertEqual((result['exit_code'], result['interrupted']), (130, True))
        self.assertNotIn('shell-integration.nu', result['output'])

    def test_finish_hook_preserves_literal_quotes_and_tmux_format_characters_in_paths(self):
        snapshots = self.base / "snapshots 'quoted' #{pane_id} $(literal) 中文"
        snapshots.mkdir(mode=0o700)
        self.env['TMPDIR'] = str(snapshots)
        task = self.start('print QUOTED_PATH_OK; exit 9')
        self.wait_done(task)
        result = json.loads(Path(task['file'] + '.result.json').read_text())
        self.assertEqual(result['exit_code'], 9)
        self.assertIn('QUOTED_PATH_OK', result['output'])

    def test_failed_command_is_archived_without_leaving_dead_pane(self):
        task = self.start('error make {msg: "EXPECTED_TASK_FAILURE"}')
        self.wait_done(task)
        result = json.loads(Path(task['file'] + '.result.json').read_text())
        self.assertNotEqual(result['exit_code'], 0)
        self.assertIn('EXPECTED_TASK_FAILURE', result['output'])

    def test_reload_migrates_finished_legacy_pane_and_preserves_output(self):
        task = self.start('print LEGACY_OUTPUT; loop { sleep 100ms }')
        deadline = time.monotonic() + 4
        while 'LEGACY_OUTPUT' not in self.tmux('capture-pane', '-p', '-t', task['pane']) and time.monotonic() < deadline:
            time.sleep(0.03)
        self.assertIn('LEGACY_OUTPUT', self.tmux('capture-pane', '-p', '-t', task['pane']))
        self.tmux('set-hook', '-p', '-u', '-t', task['pane'], 'pane-died')
        Path(task['file'] + '.ready').unlink()
        # Let the already-running worker through its gate before removing it.
        # Existing tasks from before this fix did not have a ready gate or hook.
        self.tmux('send-keys', '-t', task['pane'], 'C-c')
        deadline = time.monotonic() + 4
        while self.tmux('display-message', '-p', '-t', task['pane'], '#{pane_dead}') != '1' and time.monotonic() < deadline:
            time.sleep(0.03)
        self.assertEqual(self.tmux('display-message', '-p', '-t', task['pane'], '#{pane_dead}'), '1')
        self.nu(f'source {literal(SOURCE)}; null')
        self.wait_done(task)
        self.assertIn('LEGACY_OUTPUT', json.loads(Path(task['file'] + '.result.json').read_text())['output'])

    def test_finished_task_actions_do_not_touch_reused_foreign_pane_id(self):
        task = self.start('print SAVED_OUTPUT')
        self.wait_done(task)
        control = self.tmux('new-session', '-d', '-P', '-F', '#{pane_id}', '-s', 'foreign', 'sleep 120')
        self.nu(f'menu task-stop {literal(task["token"])}; null')
        self.nu(f'menu task-close {literal(task["token"])}; null')
        self.assertEqual(self.tmux('display-message', '-p', '-t', control, '#{pane_dead}'), '0')

    def test_failed_rerun_keeps_previous_output_and_registry(self):
        task = self.start('print PREVIOUS_OUTPUT')
        self.wait_done(task)
        before = Path(task['file'] + '.result.json').read_bytes()
        result = self.nu(f'menu task-rerun {literal(task["token"])}', check=False,
                         extra_env={'TMUX': 'nonexistent-server,1,0', 'TMUX_PANE': '%99999'})
        self.assertNotEqual(result.returncode, 0)
        self.assertEqual(Path(task['file'] + '.result.json').read_bytes(), before)
        self.assertEqual(json.loads(self.state.read_text())[-1], task)

    def test_task_cleanup_preserves_other_dead_panes(self):
        control = self.tmux('new-session', '-d', '-P', '-F', '#{pane_id}', '-s', 'control', '-x', '100', '-y', '32', 'sleep 120')
        foreign = self.tmux('split-window', '-d', '-P', '-F', '#{pane_id}', '-t', control, 'sleep 120')
        self.tmux('set-option', '-p', '-t', foreign, 'remain-on-exit', 'on')
        self.tmux('respawn-pane', '-k', '-t', foreign, NU, '-n', '-c', 'exit 8')
        socket = self.tmux('display-message', '-p', '#{socket_path}')
        pid = self.tmux('display-message', '-p', '#{pid}')
        task = self.start('print OWNED_TASK', extra_env={'TMUX': f'{socket},{pid},0', 'TMUX_PANE': control})
        self.wait_done(task)
        self.assertEqual(self.tmux('display-message', '-p', '-t', foreign, '#{pane_dead}'), '1')
        self.assertEqual(self.tmux('display-message', '-p', '-t', control, '#{pane_dead}'), '0')

    def test_explicit_close_recovers_owned_dead_pane_if_exit_hook_was_removed(self):
        task = self.start('loop { sleep 100ms }')
        self.tmux('set-hook', '-p', '-u', '-t', task['pane'], 'pane-died')
        self.nu(f'menu task-stop {literal(task["token"])}; null')
        deadline = time.monotonic() + 4
        while self.tmux('display-message', '-p', '-t', task['pane'], '#{pane_dead}') != '1' and time.monotonic() < deadline:
            time.sleep(0.03)
        self.assertEqual(self.tmux('display-message', '-p', '-t', task['pane'], '#{pane_dead}'), '1')
        self.nu(f'menu task-close {literal(task["token"])}; null')
        remaining = subprocess.run(['tmux', '-S', task['socket'], 'display-message', '-p', '-t', task['pane'], '#{@gamepad_task}'],
                                   text=True, capture_output=True)
        self.assertTrue(remaining.returncode != 0 or remaining.stdout.strip() != task['token'])
        self.assertFalse(Path(task['directory']).exists())

    def test_exit_hook_uses_calling_shell_path_instead_of_tmux_server_path(self):
        started = subprocess.run([shutil.which('tmux'), 'new-session', '-d', '-s', 'limited-env',
                                  '/bin/sleep', '120'], env=dict(self.env, PATH='/nonexistent'),
                                 text=True, capture_output=True)
        self.assertEqual(started.returncode, 0, started.stderr)
        task = self.start('print CALLER_PATH_OK')
        self.wait_done(task)
        self.assertIn('CALLER_PATH_OK', json.loads(Path(task['file'] + '.result.json').read_text())['output'])


if __name__ == '__main__':
    unittest.main(verbosity=2)

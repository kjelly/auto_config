"""Exercise the sanitized full config and directory hooks in an isolated REPL."""
import fcntl
import json
import os
from pathlib import Path
import pty
import signal
import struct
import tempfile
import termios
import unittest

import gamepad_test
from gamepad_test import NU, literal

ROOT = Path(__file__).resolve().parents[1]


class ShellReplTests(unittest.TestCase):
    read = gamepad_test.ControllerTests.read
    send = gamepad_test.ControllerTests.send
    state = gamepad_test.ControllerTests.state
    tearDown = gamepad_test.ControllerTests.tearDown

    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix='nu-shell-repl-')
        self.base = Path(self.temp.name)
        self.bin = self.base / 'bin'
        self.bin.mkdir()
        for name, body in [('direnv', 'echo "{}"'), ('zoxide', 'exit 0'), ('starship', 'printf TEST_PROMPT'), ('tmux', 'exit 1')]:
            executable = self.bin / name
            executable.write_text('#!/bin/sh\n' + body + '\n')
            executable.chmod(0o755)
        for directory, label in [('project-a', 'A'), ('project-b', 'B')]:
            p = self.base / directory
            p.mkdir()
            (p / 'local.nu').write_text(f'export def project-fixture [] {{ "{label}" }}\nexport-env {{ $env.TEST_LOCAL = "{label}" }}\n')
        (self.base / 'project-a/child').mkdir()
        (self.base / 'plain').mkdir()
        self.statefile = self.base / 'state.json'
        (self.base / 'scripts').symlink_to(ROOT / 'scripts', target_is_directory=True)
        config = self.base / 'test.nu'
        text = (ROOT / 'config.nu').read_text()
        text = text.replace('source ~/.config/custom.nu', '# private overrides excluded from fixture')
        text = text.replace("use ($nu.default-config-dir | path join 'scripts' 'pueue.nu') *", '# generated user module excluded from fixture')
        self.assertNotIn('source ~/.config/custom.nu', text)
        text = f'$env.PATH = ($env.PATH | prepend {literal(self.bin)})\n' + text
        dump = '{buffer: (commandline), cursor: (commandline get-cursor), pwd: $env.PWD, local: $env.TEST_LOCAL?, definitions: (scope commands | where name == "project-fixture" | length), ctrl_r: ($env.config.keybindings | where modifier == control and keycode == char_r | length), alt_c: ($env.config.keybindings | where {|b| ($b.modifier | str lowercase) == "alt" and $b.keycode == "char_c" } | length)} | to json | save -f ' + literal(self.statefile)
        text += '\n' + '\n'.join([
            '$env.PROMPT_COMMAND = {|| "TEST> "}',
            '$env.PROMPT_INDICATOR = ""',
            '$env.PROMPT_COMMAND_RIGHT = ""',
            '$env.TRANSIENT_PROMPT_COMMAND = "TEST> "',
            f'$env.config.keybindings ++= [{{name: dump, modifier: none, keycode: f12, mode: [emacs], event: {{send: executehostcommand, cmd: {literal(dump)}}}}}]',
            f'cd {literal(self.base / "plain")}',
        ])
        config.write_text(text)
        self.pid, self.fd = pty.fork()
        if self.pid == 0:
            os.environ['TERM'] = 'xterm-256color'
            os.environ['BASH_ENV'] = '/dev/null'
            os.environ.pop('TMUX', None)
            os.execv(NU, [NU, '-n', '--no-history', '-e', f'source {literal(config)}'])
        fcntl.ioctl(self.fd, termios.TIOCSWINSZ, struct.pack('HHHH', 32, 100, 0, 0))
        self.output = b''
        self.read(0.8)
        self.assertIn(b'TEST>', self.output, self.output.decode(errors='replace'))

    def cd(self, relative):
        self.send(f'cd {literal(self.base / relative)}\r', 0.35)
        return self.state()

    def test_completer_receives_expanded_alias_arguments(self):
        executable = self.bin / 'carapace'
        arguments = self.base / 'completer.json'
        executable.write_text('#!/usr/bin/env python3\nimport json, sys\nfrom pathlib import Path\nPath(' + repr(str(arguments)) + ').write_text(json.dumps(sys.argv[1:]))\nprint(json.dumps([dict(value="log", description="fixture")]))\n')
        executable.chmod(0o755)
        self.send('alias fixture-ga = git --no-pager\r', 0.25)
        self.send('fixture-ga lo')
        self.send(b'\t', 0.5)
        self.assertTrue(arguments.exists(), self.output.decode(errors='replace'))
        spans = json.loads(arguments.read_text())
        self.assertEqual(spans[:4], ['git', 'nushell', 'git', '--no-pager'])
        self.assertIn('lo', spans)
        self.assertNotIn(b'Error:', self.output)

    def test_failed_completer_returns_native_file_completion(self):
        executable = self.bin / 'carapace'
        executable.write_text('#!/bin/sh\nexit 7\n')
        executable.chmod(0o755)
        (self.base / 'plain/ordinary-file').touch()
        self.send('^cat ordinary-')
        self.send(b'\t', 0.5)
        self.assertIn('ordinary-file', self.state()['buffer'])
        self.assertNotIn(b'Error:', self.output)

    def test_continuous_edit_works_with_full_config_and_nushell_shell_env(self):
        self.send('print alpha beta')
        self.send(b'\x1b')
        self.send(b'\x1b[F')  # Main menu End -> management.
        self.send(b'\r', 0.35)
        self.send(b'\x1b[B' * 6)
        self.send(b'\r\r', 0.8)
        self.send(b'\x1b', 0.4)
        self.assertEqual(self.state()['buffer'], 'print ')
        self.assertNotIn(b'Error:', self.output)

    def test_full_config_has_one_history_and_one_directory_binding(self):
        state = self.state()
        self.assertEqual((state['ctrl_r'], state['alt_c']), (1, 1))
        self.assertNotIn(b'Error:', self.output)

    def test_keyboard_menu_command_works_with_full_config(self):
        self.send('menu\r', 0.35)
        self.assertIn('命令選單：'.encode(), self.output)
        self.send(b'\x1b', 0.35)
        self.assertEqual(self.state()['buffer'], '')
        self.assertNotIn(b'Error:', self.output)

    def test_bash_menu_runs_with_full_config_and_returns_to_same_nu(self):
        marker = self.base / 'bash full-config result'
        self.send('printf "%s" "$(printf bash-value)" > ' + json.dumps(str(marker)))
        self.send(b'\x1b')
        self.send(b'\x1b[H' + b'\x1b[B' * 9)  # Home -> first item; Bash is item 9.
        self.send(b'\r', 0.35)
        self.assertTrue(self.state()['buffer'].startswith('^bash '))
        self.assertFalse(marker.exists())
        self.send(b'\r', 0.35)
        self.assertEqual(marker.read_text(), 'bash-value')
        state = self.state()
        self.assertEqual((state['buffer'], state['pwd']), ('', str(self.base / 'plain')))

    def test_draft_menu_save_restore_with_full_config(self):
        self.send('print draft中文')
        self.send(b'\x1b[D' * 2)
        before = self.state()
        self.send(b'\x1b')
        self.send(b'\x1b[H' + b'\x1b[B' * 14)
        self.send(b'\r', 0.35)
        self.send(b'\r', 0.35)
        self.assertEqual(self.state()['buffer'], '')
        self.send(b'\x1b')
        self.send(b'\x1b[H' + b'\x1b[B' * 14)
        self.send(b'\r', 0.35)
        self.send(b'\x1b[B\r', 0.35)
        self.send(b'\r', 0.35)
        after = self.state()
        self.assertEqual((after['buffer'], after['cursor']), (before['buffer'], before['cursor']))

    def test_overlay_enter_leave_and_change_project(self):
        state = self.cd('project-a')
        self.assertEqual((state['local'], state['definitions']), ('A', 1))
        state = self.cd('plain')
        self.assertEqual((state['local'], state['definitions']), (None, 0))
        state = self.cd('project-b')
        self.assertEqual((state['local'], state['definitions']), ('B', 1), self.output.decode(errors='replace'))
        state = self.cd('project-a')
        self.assertEqual((state['local'], state['definitions']), ('A', 1))
        self.assertNotIn(b'Error:', self.output)

    def test_overlay_child_without_module_removes_project_settings(self):
        self.cd('project-a')
        state = self.cd('project-a/child')
        self.assertEqual((state['local'], state['definitions']), (None, 0))
        self.assertEqual(state['pwd'], str(self.base / 'project-a/child'))


if __name__ == '__main__':
    unittest.main()

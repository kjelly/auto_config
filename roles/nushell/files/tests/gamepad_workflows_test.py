"""Controller-only workflows using fake history, clipboard and project files."""
import json
import os
from pathlib import Path
import subprocess
import sys
import unittest

import gamepad_test as core


class WorkflowTests(unittest.TestCase):
    setUp = core.ControllerTests.setUp
    tearDown = core.ControllerTests.tearDown
    read = core.ControllerTests.read
    send = core.ControllerTests.send
    state = core.ControllerTests.state
    choose = core.ControllerTests.choose
    menu = core.ControllerTests.menu
    stage_fixture_buffer = core.ControllerTests.stage_fixture_buffer
    wait_for_json = core.ControllerTests.wait_for_json

    def first_path(self, *, directory=False):
        self.send(core.END)
        if directory:
            self.send(core.HOME + core.DOWN)  # Use this directory.
        self.choose()

    def test_multiple_paths_insert_quoted_arguments_without_execution(self):
        self.send('^echo ')
        self.menu('insert_paths')
        self.send(core.END)
        self.send(' ')  # ordinary-file
        self.send(core.END + b'\x1b[A')
        self.send(' ')  # quoted directory
        self.send(core.HOME)
        self.choose()
        state = self.state()
        script = state['buffer']
        self.assertTrue(script.startswith('^echo '))
        result = subprocess.run([core.NU, '-n', '-c', script.replace('^echo ', '[', 1) + '] | to json'],
                                text=True, capture_output=True, check=True)
        self.assertEqual(json.loads(result.stdout), [str(self.cwd / 'ordinary-file'), str(self.child)])
        self.assertEqual(state['pwd'], str(self.cwd))
        self.menu('undo')
        self.assertEqual(self.state()['buffer'], '^echo ')

    def test_path_selection_cancel_preserves_text_and_cursor(self):
        self.send('print 中文')
        self.send(core.LEFT)
        before = self.state()
        self.menu('insert_paths')
        self.send(core.END + b' ')
        self.send(core.ESC, 0.35)
        self.assertEqual(self.state(), before)

    def test_project_path_search_preserves_path_and_selection(self):
        self.menu('insert_paths')
        self.choose(2)  # Search project files.
        self.send('ordinary')
        self.choose()
        self.send(core.HOME)
        self.choose()
        result = subprocess.run([core.NU, '-n', '-c', '[' + self.state()['buffer'] + '] | to json'],
                                text=True, capture_output=True, check=True)
        self.assertEqual(json.loads(result.stdout), [str(self.cwd / 'ordinary-file')])

    def test_path_tab_switch_preserves_checked_paths_directory_and_query(self):
        target = self.child / "needle 'quote' $(literal) 中文.txt"
        target.touch()
        self.menu('insert_paths')
        self.send(core.END)
        self.send(' ')  # Check ordinary-file.
        self.choose(4)  # Browse the child directory after controls and '..'.
        self.send(core.TAB, 0.35)
        self.send('needle-no-match')
        self.send(core.TAB, 0.35)  # Back to the retained child directory.
        self.send(core.TAB, 0.35)
        self.send(core.BACK * len('-no-match'))
        self.choose()  # Check the search result and return to browser.
        self.send(core.HOME)
        self.choose()  # Apply both paths.
        state = self.state()
        result = subprocess.run([core.NU, '-n', '-c', '[' + state['buffer'] + '] | to json'],
                                text=True, capture_output=True, check=True)
        self.assertEqual(json.loads(result.stdout), [str(self.cwd / 'ordinary-file'), str(target)])
        self.assertEqual(state['pwd'], str(self.cwd))

    def test_path_tab_switch_empty_search_back_and_cancel_preserve_buffer(self):
        (self.cwd / 'ordinary-file').unlink()
        self.send('print 中文')
        self.send(core.LEFT)
        before = self.state()
        self.menu('insert_paths')
        self.send(core.TAB, 0.35)
        self.send(core.TAB, 0.35)
        self.send(core.TAB, 0.35)
        self.send(core.BACK, 0.35)  # Empty search returns to browser.
        self.send(core.ESC, 0.35)
        self.assertEqual(self.state(), before)

    def test_single_path_template_supports_tab_mode_switch(self):
        self.menu('templates')
        self.choose()  # Compare files.
        for _ in range(2):
            self.send(core.TAB, 0.35)
            self.send('ordinary')
            self.choose()
        command = self.state()['buffer']
        self.assertTrue(command.startswith('^diff -- '), command)
        arguments = command.removeprefix('^diff -- ')
        result = subprocess.run([core.NU, '-n', '-c', '[' + arguments + '] | to json'],
                                text=True, capture_output=True, check=True)
        self.assertEqual(json.loads(result.stdout), [str(self.cwd / 'ordinary-file'),
                                                   str(self.cwd / 'ordinary-file')])

    def test_template_compare_files_stages_without_running(self):
        self.menu('templates')
        self.choose()  # Compare two files.
        self.first_path()
        self.first_path()
        staged = self.state()['buffer']
        self.assertTrue(staged.startswith('^diff -- '), staged)
        self.assertEqual(staged.count('ordinary-file'), 2)

    def test_template_back_goes_to_previous_parameter_and_escape_preserves_buffer(self):
        self.send('print keep')
        before = self.state()
        self.menu('templates')
        self.choose()
        self.first_path()
        self.send(core.BACK, 0.35)
        self.assertIn('第一個檔案'.encode(), self.output[-4000:])
        self.send(core.ESC, 0.35)
        self.assertEqual(self.state(), before)

    def test_first_template_parameter_back_returns_to_template_list(self):
        self.menu('templates')
        self.choose()
        self.send(core.BACK, 0.35)
        self.assertIn('比較兩個檔案'.encode(), self.output[-5000:])
        self.assertIn('參數化收藏'.encode(), self.output[-5000:])
        self.send(core.ESC, 0.35)
        self.assertEqual(self.state()['buffer'], '')

    def test_custom_parameterized_favorite_choice_is_literal(self):
        marker = self.base / 'not executed'
        value = '中文 $(touch ' + str(marker) + ') {{other}} \\value'
        self.favorites.write_text(json.dumps([{'label': 'CHOICE TEMPLATE', 'command': 'print {{value}}',
                                             'parameters': [{'name': 'value', 'kind': 'choice', 'choices': [value]}]}], ensure_ascii=False))
        self.menu('favorites')
        self.choose()
        self.choose()
        self.assertFalse(marker.exists())

        result = subprocess.run([core.NU, '-n', '-c', self.state()['buffer']],
                                text=True, capture_output=True, check=True)
        self.assertEqual(result.stdout.rstrip('\n'), value)
        self.assertFalse(marker.exists())

    def test_template_history_field_defaults_to_local_and_stages_literal(self):
        self.favorites.write_text(json.dumps([{'label': 'HISTORY FIELD', 'command': 'print {{value}}',
                                             'parameters': [{'name': 'value', 'kind': 'history'}]}]))
        self.menu('favorites')
        self.choose()
        self.assertIn('目前目錄'.encode(), self.output[-6000:])
        self.choose(2)  # all / print / go
        self.choose()
        result = subprocess.run([core.NU, '-n', '-c', self.state()['buffer']],
                                text=True, capture_output=True, check=True)
        self.assertEqual(result.stdout, 'go build ./...\n')

    def fake_clipboard(self, text):
        bindir = self.base / 'bin'
        bindir.mkdir()
        clip = self.base / 'clipboard.txt'
        clip.write_text(text)
        for program, body in [('wl-paste', f'import sys; sys.stdout.write(open({str(clip)!r}).read())'),
                              ('wl-copy', f'import sys; open({str(clip)!r}, "w").write(sys.stdin.read())')]:
            executable = bindir / program
            executable.write_text(f'#!{sys.executable}\n{body}\n')
            executable.chmod(0o755)
        self.send(f'$env.PATH = ($env.PATH | prepend {core.literal(bindir)}); $env.WAYLAND_DISPLAY = "fixture"\r')
        return clip

    def test_clipboard_raw_preserves_multiline_and_trailing_newlines(self):
        text = 'first\\line\n中文 "quoted"\n\n'
        self.fake_clipboard(text)
        self.send('prefix ')
        self.menu('clipboard')
        self.choose()
        self.assertEqual(self.state()['buffer'], 'prefix ' + text)

    def test_clipboard_as_argument_does_not_execute_substitution(self):
        text = '$(printf NOT_RUN)\n"quoted" \\literal\n'
        self.fake_clipboard(text)
        self.send('print ')
        self.menu('clipboard')
        self.choose(1)
        result = subprocess.run([core.NU, '-n', '-c', self.state()['buffer']],
                                text=True, capture_output=True, check=True)
        self.assertEqual(result.stdout, text + '\n')

    def test_copy_command_writes_clipboard_without_running_command(self):
        clip = self.fake_clipboard('old')
        self.send('printf command-only')
        self.menu('clipboard')
        self.choose(4)
        self.assertEqual(clip.read_text(), 'printf command-only')
        self.send(core.ESC, 0.35)
        self.assertEqual(self.state()['buffer'], 'printf command-only')

    def test_cb_save_then_select_restores_text(self):
        self.send('print 中文')
        self.menu('clipboard')
        self.choose(5)
        self.send(core.ESC, 0.35)
        self.menu('clear')
        self.menu('clipboard')
        self.choose(2)
        self.choose()
        self.assertEqual(self.state()['buffer'], 'print 中文')

    def test_history_program_filter_without_typing(self):
        self.menu('history_programs')
        self.choose(2)  # all / print / go
        self.choose()
        self.assertEqual(self.state()['buffer'], 'go build ./...')

    def test_history_program_global_and_status_controls_without_typing(self):
        self.menu('history_programs')
        self.send(core.RIGHT, 0.35)
        self.send(core.TAB, 0.35)  # success
        self.choose(1)  # print
        self.choose()
        self.assertEqual(self.state()['buffer'], 'print OTHER')

    def test_history_program_empty_filter_can_switch_scope(self):
        self.menu('history_programs')
        self.choose(1)  # print
        self.send(core.TAB, 0.35)
        self.send(core.TAB, 0.35)  # failed: no print matches.
        self.send(core.LEFT, 0.35)
        self.send(core.TAB, 0.35)  # all again
        self.choose()
        self.assertEqual(self.state()['buffer'], 'print FIRST\nprint SECOND')

    def test_draft_restore_keeps_grapheme_cursor_and_current_directory(self):
        self.stage_fixture_buffer('print "👨‍👩‍👧‍👦é中文"')
        self.send(core.LEFT * 2)
        before = self.state()
        self.menu('drafts')
        self.choose()
        self.assertEqual(self.state()['buffer'], '')
        self.send(f'cd {core.literal(self.child)}\r')
        self.menu('drafts')
        self.choose(1)
        self.choose()
        restored = self.state()
        self.assertEqual((restored['buffer'], restored['cursor']), (before['buffer'], before['cursor']))
        self.assertEqual(restored['pwd'], str(self.child))

    def test_drafts_are_multiple_and_survive_resourcing(self):
        for text in ['print first', 'print second']:
            self.send(text)
            self.menu('drafts')
            self.choose()
        self.send(f'source {core.literal(core.SOURCE)}\r')
        self.menu('drafts')
        self.choose(1)
        self.choose(1)  # older first draft
        self.assertEqual(self.state()['buffer'], 'print first')


class WorkflowValueTests(unittest.TestCase):
    def nu(self, expression, *, check=True):
        result = subprocess.run([core.NU, '-n', '-c', f'source {core.literal(core.SOURCE)}; {expression} | to json'],
                                text=True, capture_output=True)
        if not check:
            return result
        self.assertEqual(result.returncode, 0, result.stderr)
        return json.loads(result.stdout)

    def test_template_repeated_placeholder_does_not_expand_inserted_placeholders(self):
        result = self.nu('menu render-template {command: "print {{x}} {{x}}", parameters: '
                         '[{name: x, kind: choice, choices: [a]}]} {x: "{{x}} $literal \\u{005c}value"}')
        command = subprocess.run([core.NU, '-n', '-c', result], text=True, capture_output=True, check=True)
        self.assertEqual(command.stdout, '{{x}} $literal \\value\n{{x}} $literal \\value\n')

    def test_template_rejects_quoted_unknown_and_duplicate_fields(self):
        templates = [
            {'command': 'print "{{x}}"', 'parameters': [{'name': 'x', 'kind': 'file'}]},
            {'command': 'print {{unknown}}', 'parameters': []},
            {'command': 'print {{x}}', 'parameters': [{'name': 'x', 'kind': 'file'}] * 2},
            {'command': 'print {{x}}', 'parameters': [{'name': 'x', 'kind': 'choice', 'choices': []}]},
        ]
        for template in templates:
            with self.subTest(template=template):
                result = self.nu('menu render-template ' + json.dumps(template) + ' {x: "literal"}', check=False)
                self.assertNotEqual(result.returncode, 0)

    def test_history_program_groups_are_literal_and_keep_recent_order(self):
        items = self.nu('[{command: "^git status"}, {command: "git diff"}, {command: "go test"}] | menu history-program-items')
        self.assertEqual([item['program'] for item in items], ['git', 'go'])
        self.assertEqual(items[0]['label'], 'git（2 筆）')


if __name__ == '__main__':
    unittest.main(verbosity=2)

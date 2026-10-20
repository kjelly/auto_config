"""Real input list fallback in an isolated PTY whose PATH contains no fzf.

Run: python3 tests/gamepad_native_test.py
"""
import json
import shutil
import sqlite3
import subprocess
import unittest

import gamepad_test as core


@unittest.skipUnless(core.NU, 'requires Nushell')
class NativeMenuTests(unittest.TestCase):
    tearDown = core.ControllerTests.tearDown
    read = core.ControllerTests.read
    send = core.ControllerTests.send
    state = core.ControllerTests.state
    choose = core.ControllerTests.choose
    menu = core.ControllerTests.menu
    wait_for_json = core.ControllerTests.wait_for_json

    def setUp(self):
        core.ControllerTests.setUp(self)
        bindir = self.base / 'without-fzf'
        bindir.mkdir()
        if shutil.which('git'):
            (bindir / 'git').symlink_to(shutil.which('git'))
        self.send(f'$env.PATH = [{core.literal(bindir)}]\r')
        self.output = b''

    def control(self, label):
        """Filter a fuzzy menu to an explicit navigation option."""
        self.send(label)
        self.choose()

    def test_favorite_stages_literal_command_without_executing(self):
        marker = self.base / 'not executed'
        command = f'"中文 $(literal)" | save {core.literal(marker)}'
        self.favorites.write_text('[{label: "← 返回\\n\\e[31m", command: '
                                  + core.literal(command) + '}]')
        self.send('menu\r', 0.35)
        self.choose()  # Favorites.
        self.choose()  # The data row, even though its label looks like Back.
        self.assertEqual(self.state()['buffer'], command, self.output[-6000:].decode(errors='replace'))
        self.assertFalse(marker.exists())

    def test_explicit_back_and_escape_preserve_buffer_and_cursor(self):
        self.send('print 中文')
        self.send(core.LEFT)
        before = self.state()
        self.menu('favorites')
        self.choose(1)  # Explicit Back follows the favorite.
        self.assertIn('命令選單：'.encode(), self.output[-6000:])
        self.assertNotIn(b'Backspace', self.output[-2500:])
        self.send(core.ESC, 0.35)
        self.assertEqual(self.state(), before)

    def test_remove_favorite_uses_original_index(self):
        self.favorites.write_text(json.dumps([
            {'label': 'duplicate', 'command': 'print FIRST'},
            {'label': 'duplicate', 'command': 'print SECOND'},
        ]))
        self.menu('manage')
        self.choose(1)  # Remove favorite.
        self.choose(1)  # Remove the second of two identical labels.
        self.send(core.ESC, 0.35)
        result = subprocess.run([core.NU, '-n', '-c',
                                 f'open {core.literal(self.favorites)} | to json'],
                                text=True, capture_output=True, check=True)
        self.assertEqual(json.loads(result.stdout), [{'label': 'duplicate', 'command': 'print FIRST'}])

    def test_history_range_status_and_search_backspace(self):
        self.send(b'\x12', 0.35)
        self.control('切換範圍：全域')
        self.assertIn('歷史：全域 / 全部'.encode(), self.output[-7000:])
        self.control('切換狀態')
        self.assertIn('歷史：全域 / 成功'.encode(), self.output[-7000:])
        self.control('切換狀態')
        self.assertIn('歷史：全域 / 失敗或中斷'.encode(), self.output[-7000:])
        self.send('buildx')
        self.send(core.BACK)  # Delete a query character, not Back.
        self.choose()
        self.assertEqual(self.state()['buffer'], 'go build ./...')

    def test_empty_history_can_switch_range_and_return(self):
        with sqlite3.connect(self.historydb) as db:
            db.execute('DELETE FROM history WHERE cwd = ?', (str(self.cwd),))
        self.send(b'\x12', 0.35)
        self.control('切換範圍：全域')
        self.assertIn('print OTHER'.encode(), self.output[-6000:])
        self.control('← 返回')
        self.assertIn('命令選單：'.encode(), self.output[-6000:])
        self.send(core.ESC, 0.35)
        self.assertEqual(self.state()['buffer'], '')

    def test_file_browser_switches_to_search_and_back(self):
        self.menu('files')
        self.choose()  # Directory browser: parent, directory, ordinary-file.
        self.choose(4)  # Mode switch follows the three entries and Back.
        self.assertIn('檔案：專案搜尋'.encode(), self.output[-6000:])
        self.control('切換搜尋模式')
        self.assertIn('檔案：目錄瀏覽'.encode(), self.output[-6000:])
        self.choose(4)
        self.send('ordinary')
        self.choose()
        command = self.state()['buffer']
        self.assertTrue(command.startswith('^nvim '), command)
        self.assertIn('ordinary-file', command)

    def test_directory_can_be_checked_without_entering_and_paths_stay_literal(self):
        self.send('^echo ')
        self.menu('insert_paths')
        # Apply, use current, search, parent, parent toggle, child, child toggle.
        self.choose(6)
        self.assertIn('已選 1 項'.encode(), self.output[-9000:])
        self.choose(7)  # ordinary-file after the child's toggle option.
        self.assertIn('已選 2 項'.encode(), self.output[-9000:])
        self.choose()  # Apply.
        state = self.state()
        result = subprocess.run([core.NU, '-n', '-c',
                                 '[' + state['buffer'].removeprefix('^echo ') + '] | to json'],
                                text=True, capture_output=True, check=True)
        self.assertEqual(json.loads(result.stdout), [str(self.child), str(self.cwd / 'ordinary-file')])
        self.assertEqual(state['pwd'], str(self.cwd))

    def test_single_file_template_uses_explicit_search_switch_for_each_parameter(self):
        self.menu('templates')
        self.choose()  # Compare two files.
        for _ in range(2):
            # Apply, search, parent/toggle, child/toggle, file, Back, mode switch.
            self.choose(8)
            self.send('ordinary')
            self.choose()
        command = self.state()['buffer']
        self.assertTrue(command.startswith('^diff -- '), command)
        result = subprocess.run([core.NU, '-n', '-c',
                                 '[' + command.removeprefix('^diff -- ') + '] | to json'],
                                text=True, capture_output=True, check=True)
        self.assertEqual(json.loads(result.stdout), [str(self.cwd / 'ordinary-file')] * 2)

    def test_no_match_escape_preserves_existing_command(self):
        self.send('print keep')
        self.send(core.LEFT)
        before = self.state()
        self.send(b'\x12', 0.35)
        self.send('no-such-history-or-control')
        self.send(core.ESC, 0.35)
        self.assertEqual(self.state(), before)

    def test_program_history_uses_explicit_scope_option_without_typing(self):
        self.menu('history_programs')
        # All programs, go, print, Back, local, global, status.
        self.choose(5)
        self.assertIn('免打字歷史：全域'.encode(), self.output[-7000:])
        self.choose()  # All programs.
        self.choose()  # Most recent global command.
        self.assertEqual(self.state()['buffer'], 'print OTHER')

    def test_management_reopens_updated_preview_and_undo_restores_command(self):
        self.send('print FIRST SECOND')
        self.menu('manage')
        self.choose(6)  # Delete previous word.
        self.assertIn('命令： print FIRST'.encode(), self.output[-7000:])
        self.choose(6)  # Delete previous word again.
        self.send(core.ESC, 0.35)
        self.assertEqual(self.state()['buffer'], 'print ')
        self.menu('undo')
        self.assertEqual(self.state()['buffer'], 'print FIRST ')

    def test_native_picker_empty_items_and_cancel_contract(self):
        resultfile = self.base / 'picker.json'
        self.send(f'menu pick [] EMPTY --fuzzy --history-controls | to json | save -f {core.literal(resultfile)}\r', 0.35)
        self.control('切換範圍：全域')
        self.assertEqual(self.wait_for_json(resultfile), {'key': 'right', 'query': ''})
        resultfile.unlink()
        self.send(f'menu pick [] EMPTY | to json | save -f {core.literal(resultfile)}\r', 0.35)
        self.send(core.ESC, 0.35)
        self.assertEqual(self.wait_for_json(resultfile), {'key': 'cancel'})


if __name__ == '__main__':
    unittest.main()

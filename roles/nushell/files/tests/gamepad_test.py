"""Run with python3 tests/gamepad_test.py (Nushell 0.116+ and fzf).

Uses an isolated PTY, fake favorites/history, and temporary directories. It never
loads config.nu, user history, custom.nu, or any startup hooks.
"""
import fcntl
import json
import os
from pathlib import Path
import pty
import select
import shlex
import shutil
import signal
import sqlite3
import struct
import subprocess
import sys
import tempfile
import termios
import time
import unittest


ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "scripts/gamepad.nu"
NU = shutil.which("nu")
ESC, ENTER, DOWN, LEFT, RIGHT, TAB, BACK = (
    b"\x1b", b"\r", b"\x1b[B", b"\x1b[D", b"\x1b[C", b"\t", b"\x7f"
)
HOME, END, SHIFT_TAB, PAGE_UP, PAGE_DOWN = b"\x1b[H", b"\x1b[F", b"\x1b[Z", b"\x1b[5~", b"\x1b[6~"


def literal(value):
    return json.dumps(str(value), ensure_ascii=False)


class ControllerTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix="nu-gamepad-")
        self.base = Path(self.temp.name)
        self.cwd = self.base / "work"
        self.cwd.mkdir()
        self.child = self.cwd / "a 'quoted' \"dir\" $(literal) 中文"
        self.child.mkdir()
        (self.cwd / "ordinary-file").touch()
        self.favorites = self.base / "favorites.nuon"
        self.favorites.write_text('[{label: "TEST FAVORITE", command: "print TEST_EXECUTED"}]')
        self.sessiontemp = self.base / "sessions 'quoted' (safe) $literal"
        self.sessiontemp.mkdir()
        self.statefile = self.base / "state.json"
        self.historydb = self.base / "history.sqlite3"
        with sqlite3.connect(self.historydb) as db:
            db.execute("CREATE TABLE history (id INTEGER PRIMARY KEY, command_line TEXT, cwd TEXT, exit_status INTEGER)")
            db.executemany("INSERT INTO history (command_line, cwd, exit_status) VALUES (?, ?, ?)", [
                ('print "中文追加" | str length', str(self.cwd), 0),
                ('go build ./...', str(self.cwd), 1),
                ('print FIRST\nprint SECOND', str(self.cwd), 0),
                ('print OTHER', '/elsewhere', 0),
            ])
        db.close()
        config = self.base / "test.nu"
        config.write_text("\n".join([
            "$env.config.show_banner = false",
            "$env.PROMPT_COMMAND = {|| 'TEST> '}",
            "$env.PROMPT_COMMAND_RIGHT = ''",
            f"$env.GAMEPAD_FAVORITES_FILE = {literal(self.favorites)}",
            f"$env.NU_HISTORY_DATABASE = {literal(self.historydb)}",
            f"cd {literal(self.cwd)}",
            f"source {literal(SOURCE)}",
            # Model config.nu's Tab customization without loading its side effects.
            "$env.config.keybindings ++= [{name: test_tab, modifier: none, keycode: tab, mode: [emacs], event: {until: [{send: menu, name: ide_completion_menu}, {send: menunext}, {edit: complete}]}}]",
            "def gamepad-test-alpha [] {}; def gamepad-test-beta [] {}",
            "$env.config.keybindings ++= [{name: test_dump, modifier: none, keycode: f12, mode: [emacs], event: {send: executehostcommand, cmd: "
            + literal("{buffer: (commandline), cursor: (commandline get-cursor), pwd: $env.PWD} | to json | save -f " + literal(self.statefile))
            + "}}]",
        ]))
        self.pid, self.fd = pty.fork()
        if self.pid == 0:
            os.environ["TERM"] = "xterm-256color"
            os.environ["TMPDIR"] = str(self.sessiontemp)
            os.environ["BASH_ENV"] = "/dev/null"  # Never source private Bash hooks.
            os.execv(NU, [NU, "-n", "--no-history", "-e", f"source {literal(config)}"])
        fcntl.ioctl(self.fd, termios.TIOCSWINSZ, struct.pack("HHHH", 32, 100, 0, 0))
        self.output = b""
        self.read(0.6)
        self.assertIn(b"TEST>", self.output)

    def test_ctrl_r_uses_local_history_and_cancel_preserves_cursor(self):
        self.send('go ')
        self.send(b"\x12", 0.35)
        self.assertIn('歷史：目前目錄'.encode(), self.output)
        self.send(ESC, 0.35)
        self.assertEqual(self.state()['buffer'], 'go ')
        self.send(b"\x12", 0.35)
        self.choose()
        self.assertEqual(self.state()['buffer'], 'go build ./...')

    def test_typed_menu_stages_command_and_waits_for_another_enter(self):
        marker = self.base / 'keyboard-confirmed'
        command = f'"confirmed" | save {literal(marker)}'
        self.favorites.write_text(json.dumps([{'label': 'KEYBOARD FAVORITE', 'command': command}]))
        self.send('menu\r', 0.35)
        self.choose()  # favorites
        self.choose()
        self.assertEqual(self.state()['buffer'], command)
        self.assertFalse(marker.exists())
        self.send(ENTER, 0.35)
        self.assertEqual(marker.read_text(), 'confirmed')

    def test_typed_menu_cancel_returns_to_usable_prompt(self):
        self.send('menu\r', 0.35)
        self.send(ESC, 0.35)
        self.assertEqual(self.state()['buffer'], '')

    def test_typed_menu_history_defaults_to_current_directory(self):
        self.send('menu history\r', 0.35)
        self.assertIn('歷史：目前目錄'.encode(), self.output)
        self.choose()
        self.assertEqual(self.state()['buffer'], 'print FIRST\nprint SECOND')

    def test_typed_menu_history_global(self):
        self.send('menu history --global\r', 0.35)
        self.assertIn('歷史：全域'.encode(), self.output)
        self.choose()
        self.assertEqual(self.state()['buffer'], 'print OTHER')

    def test_typed_history_skips_its_pending_launcher_record(self):
        db = sqlite3.connect(self.historydb)
        try:
            db.execute('INSERT INTO history (command_line, cwd, exit_status) VALUES (?, ?, NULL)',
                       ('menu history', str(self.cwd)))
            db.commit()
        finally:
            db.close()
        self.send('menu history\r', 0.35)
        self.choose()
        self.assertEqual(self.state()['buffer'], 'print FIRST\nprint SECOND')

    def tearDown(self):
        if hasattr(self, "pid") and self.pid:
            try:
                os.kill(self.pid, signal.SIGTERM)
            except ProcessLookupError:
                pass
            os.waitpid(self.pid, 0)
            os.close(self.fd)
        self.temp.cleanup()

    def read(self, duration=0.18):
        data = b""
        deadline = time.monotonic() + duration
        while time.monotonic() < deadline:
            if select.select([self.fd], [], [], 0.02)[0]:
                try:
                    chunk = os.read(self.fd, 65536)
                except OSError:
                    break
                if not chunk:
                    break
                data += chunk
                if b"\x1b[6n" in chunk:
                    os.write(self.fd, b"\x1b[1;1R")
        self.output += data
        return data

    def send(self, keys, wait=0.18):
        os.write(self.fd, keys.encode() if isinstance(keys, str) else keys)
        return self.read(wait)

    def state(self):
        self.statefile.unlink(missing_ok=True)
        self.send(b"\x1b[24~")
        self.assertTrue(self.statefile.exists(), self.output[-4000:].decode(errors="replace"))
        return json.loads(self.statefile.read_text())

    def wait_for_json(self, path, predicate=lambda value: True):
        """Wait for the child process's result rather than a fixed delay."""
        deadline = time.monotonic() + 3
        while time.monotonic() < deadline:
            try:
                value = json.loads(path.read_text())
                if predicate(value):
                    return value
            except (FileNotFoundError, json.JSONDecodeError):
                pass
            self.read(0.05)
        self.fail(f"Timed out waiting for {path.name}: "
                  + self.output[-4000:].decode(errors="replace"))

    def choose(self, index=0):
        for _ in range(index):
            self.send(DOWN, 0.03)
        return self.send(ENTER, 0.35)

    def menu(self, action="favorites", *, stay_open=False):
        if action == "history_all":
            self.menu("history_here")
            return self.send(RIGHT, 0.35)
        management = {"add_favorite": 0, "remove_favorite": 1, "clear": 2, "undo": 3,
                      "line_start": 4, "line_end": 5, "delete_word": 6,
                      "previous_char": 7, "next_char": 8, "previous_word": 9, "next_word": 10,
                      "delete_next_word": 11, "delete_previous_char": 12, "delete_next_char": 13}
        if action in management:
            self.menu("manage")
            output = self.choose(management[action])
            if action in list(management)[4:] and not stay_open:
                output += self.close_editor()
            return output
        index = {"favorites": 0, "history_here": 1, "snippets": 2, "project": 3,
                 "files": 4, "git": 5, "tmux": 6, "directories": 7,
                 "edit": 8, "bash": 9, "insert_paths": 10, "templates": 11, "clipboard": 12,
                 "history_programs": 13, "drafts": 14, "tasks": 15, "manage": 16}[action]
        self.send(ESC)
        return self.choose(index)

    def stage_fixture_buffer(self, buffer):
        self.favorites.write_text(json.dumps([{'label': 'FIXTURE', 'command': buffer}], ensure_ascii=False))
        self.menu('favorites')
        self.choose()
        self.assertEqual(self.state()['buffer'], buffer)

    def test_bash_stages_without_execution_and_undo_restores_cursor(self):
        marker = self.base / 'must not run'
        script = 'printf "%s" "中文 $(printf value)" > ' + shlex.quote(str(marker))
        self.stage_fixture_buffer(script)
        self.send(LEFT * 3)
        before = self.state()
        self.menu('bash')
        staged = self.state()
        self.assertTrue(staged['buffer'].startswith('^bash '))
        self.assertIn('--noprofile', staged['buffer'])
        self.assertEqual(staged['cursor'], len(staged['buffer']))
        self.assertFalse(marker.exists())
        self.menu('undo')
        self.assertEqual(self.state(), before)
        self.assertFalse(marker.exists())

    def test_bash_empty_buffer_reports_notice_without_changes(self):
        before = self.state()
        self.menu('bash')
        self.assertIn('請先將'.encode(), self.output)
        self.send(ESC, 0.35)
        self.assertEqual(self.state(), before)

    def test_bash_missing_executable_reports_notice_without_changes(self):
        bindir = self.base / 'fzf-only'
        bindir.mkdir()
        (bindir / 'fzf').symlink_to(shutil.which('fzf'))
        self.send(f'$env.PATH = [{literal(bindir)}]\r')
        self.send('echo keep')
        before = self.state()
        self.menu('bash')
        self.assertIn('找不到 Bash'.encode(), self.output)
        self.send(ESC, 0.35)
        self.assertEqual(self.state(), before)

    def test_bash_failure_returns_to_nu_and_keeps_parent_environment(self):
        witness = self.base / 'bash-status.json'
        self.send('$env.GAMEPAD_BASH_TEST = "parent"\r')
        script = f'cd {shlex.quote(str(self.child))}; export GAMEPAD_BASH_TEST=child; exit 7'
        self.stage_fixture_buffer(script)
        self.menu('bash')
        self.send(ENTER, 0.35)
        self.send('{status: $env.LAST_EXIT_CODE, marker: $env.GAMEPAD_BASH_TEST, pwd: $env.PWD}'
                  f' | to json | save -f {literal(witness)}\r')
        self.assertEqual(self.wait_for_json(witness),
                         {'status': 7, 'marker': 'parent', 'pwd': str(self.cwd)})
        self.assertEqual(self.state()['buffer'], '')

    def test_bash_reads_from_terminal_and_returns_to_nu(self):
        marker = self.base / 'interactive answer'
        self.stage_fixture_buffer('printf BASH_READ_READY; read -r answer; '
                                  f'printf "%s" "$answer" > {shlex.quote(str(marker))}')
        self.menu('bash')
        self.send(ENTER, 0.35)
        self.assertIn(b'BASH_READ_READY', self.output)
        self.assertFalse(marker.exists())
        self.send('controller 中文 input\r', 0.35)
        self.assertEqual(marker.read_text(), 'controller 中文 input')
        self.assertEqual(self.state()['buffer'], '')

    def test_bash_ctrl_c_returns_to_nu(self):
        marker = self.base / 'ready'
        self.stage_fixture_buffer(f'printf ready > {shlex.quote(str(marker))}; read -r answer')
        self.menu('bash')
        self.send(ENTER, 0.35)
        self.assertTrue(marker.exists())
        self.send(b'\x03', 0.35)
        self.assertEqual(self.state()['buffer'], '')

    def test_plain_picker_home_end_select_first_last_with_terminal_variants(self):
        self.favorites.write_text(json.dumps([{'label': f'ITEM {i}', 'command': f'print ITEM_{i}'} for i in range(30)]))
        for home, end in [(HOME, END), (b'\x1b[1~', b'\x1b[4~')]:
            with self.subTest(home=home):
                self.menu('favorites')
                self.send(end)
                self.choose()
                self.assertEqual(self.state()['buffer'], 'print ITEM_29')
                self.menu('favorites')
                self.send(end + home)
                self.choose()
                self.assertEqual(self.state()['buffer'], 'print ITEM_0')

    def test_main_home_end_reach_management_and_favorites(self):
        self.send(ESC)
        self.send(END)
        self.choose()
        self.assertIn('游標移到目前行首'.encode(), self.output)
        self.send(BACK)
        self.send(END + HOME)
        self.choose()
        self.choose()
        self.assertEqual(self.state()['buffer'], 'print TEST_EXECUTED')

    def test_search_home_end_edit_query_and_preserve_it_across_scope_change(self):
        self.menu('history_here')
        self.send('FIRS')
        self.send(HOME)
        self.send('print ')
        self.send(END)
        self.send('T')
        self.send(RIGHT, 0.35)
        self.choose()
        self.assertEqual(self.state()['buffer'], 'print FIRST\nprint SECOND')

    def test_empty_search_home_end_keep_selected_row(self):
        self.menu('history_here')
        self.send(DOWN)  # go build, between the two print commands.
        self.send(HOME + END)
        self.choose()
        self.assertEqual(self.state()['buffer'], 'go build ./...')

    def test_directory_home_end_navigate_items_without_changing_pwd(self):
        self.menu('directories')
        self.send(END)
        self.choose()  # Last directory is the quoted child.
        self.send(HOME)
        self.choose()  # First item stages use-this-directory.
        state = self.state()
        self.assertEqual(state['pwd'], str(self.cwd))
        self.assertTrue(state['buffer'].startswith('cd '))
        self.send(ENTER)
        self.assertEqual(self.state()['pwd'], str(self.child))

    def test_shift_tab_moves_back_in_plain_and_search_menus(self):
        self.favorites.write_text(json.dumps([{'label': f'ITEM {i}', 'command': f'print ITEM_{i}'} for i in range(3)]))
        self.menu('favorites')
        self.send(TAB + SHIFT_TAB)
        self.choose()
        self.assertEqual(self.state()['buffer'], 'print ITEM_0')
        self.menu('history_here')
        self.send(SHIFT_TAB)  # Wrap up from first to last without changing status.
        self.choose()
        self.assertEqual(self.state()['buffer'], 'print "中文追加" | str length')

    def test_page_up_down_navigate_long_list(self):
        self.favorites.write_text(json.dumps([{'label': f'ITEM {i:02}', 'command': f'print ITEM_{i}'} for i in range(40)]))
        self.menu('favorites')
        self.send(PAGE_DOWN)
        self.choose()
        index = int(self.state()['buffer'].rsplit('_', 1)[1])
        self.assertGreater(index, 0)
        self.assertLess(index, 39)
        self.menu('favorites')
        self.send(PAGE_DOWN + PAGE_UP)
        self.choose()
        self.assertEqual(self.state()['buffer'], 'print ITEM_0')

    def test_line_cursor_actions_respect_unicode_multiline_and_undo(self):
        buffer = 'print "中文🙂"\nprint "尾巴xyz"\nprint LAST'
        self.stage_fixture_buffer(buffer)
        cursor = len('print "中文🙂"\nprint "尾巴')
        self.send(LEFT * (len(buffer) - cursor))
        before = self.state()
        self.menu('line_start')
        self.assertEqual(self.state(), dict(before, cursor=len('print "中文🙂"\n')))
        self.menu('undo')
        self.assertEqual(self.state(), before)
        self.menu('line_end')
        self.assertEqual(self.state(), dict(before, cursor=len('print "中文🙂"\nprint "尾巴xyz"')))
        self.menu('undo')
        self.assertEqual(self.state(), before)

    def test_cursor_noop_on_empty_buffer_does_not_hide_last_undo(self):
        self.send('print ORIGINAL')
        self.menu('clear')
        self.menu('line_start')
        self.menu('line_end')
        self.menu('delete_word')
        self.assertEqual(self.state()['buffer'], '')
        self.menu('undo')
        self.assertEqual(self.state()['buffer'], 'print ORIGINAL')

    def test_delete_word_keeps_right_text_and_can_undo(self):
        buffer = 'go run 中文🙂 --flag tail'
        self.stage_fixture_buffer(buffer)
        self.send(LEFT * len(' tail'))
        before = self.state()
        self.menu('delete_word')
        state = self.state()
        self.assertEqual(state['buffer'], 'go run 中文🙂  tail')
        self.assertEqual(state['cursor'], len('go run 中文🙂 '))
        self.menu('undo')
        self.assertEqual(self.state(), before)

    def close_editor(self):
        output = self.send(ESC, 0.15)
        deadline = time.monotonic() + 4
        while b'TEST>' not in output and time.monotonic() < deadline:
            output += self.read(0.05)
        self.assertIn(b'TEST>', output, self.output[-3000:].decode(errors='replace'))
        return output

    def choose_edit_action(self, index):
        self.send(HOME, 0.04)
        return self.choose(index)

    def test_repeat_delete_word_and_undo_stay_open_and_retain_selection(self):
        buffer = 'print alpha 中文🙂 --flag tail'
        self.stage_fixture_buffer(buffer)
        self.menu('delete_word', stay_open=True)
        self.send(ENTER * 2, 0.7)
        self.choose_edit_action(3)  # undo third deletion, staying on Undo.
        self.send(ENTER)  # undo second deletion.
        self.close_editor()
        state = self.state()
        self.assertEqual(state['buffer'], 'print alpha 中文🙂 --flag ')
        self.assertEqual(state['cursor'], len(state['buffer']))

    def test_continuous_word_navigation_preserves_buffer_and_right_text(self):
        buffer = 'go run 中文🙂 --flag tail'
        self.stage_fixture_buffer(buffer)
        self.menu('previous_word', stay_open=True)
        self.send(ENTER)  # Before --flag, after two backward words.
        self.choose_edit_action(10)  # Next word ends after --flag.
        self.choose_edit_action(11)  # Delete next word, preserving left text.
        self.close_editor()
        state = self.state()
        self.assertEqual(state['buffer'], 'go run 中文🙂 --flag')
        self.assertEqual(state['cursor'], len(state['buffer']))

    def test_repeat_character_movement_keeps_combining_and_emoji_clusters(self):
        family = '👨‍👩‍👧‍👦'
        buffer = 'a' + family + 'é中b'
        self.stage_fixture_buffer(buffer)
        self.menu('previous_char', stay_open=True)
        self.send(ENTER * 3, 0.8)  # b, 中, e+accent, family.
        self.choose_edit_action(8)  # Advance across the entire family emoji.
        self.close_editor()
        state = self.state()
        self.assertEqual(state['buffer'], buffer)
        self.assertEqual(state['cursor'], 2)

    def test_repeat_character_deletion_and_empty_noops_preserve_undo(self):
        self.stage_fixture_buffer('a👨‍👩‍👧‍👦é中')
        self.send(LEFT)
        self.menu('delete_previous_char', stay_open=True)
        self.send(ENTER * 2, 0.7)  # Remove accent cluster, family, a.
        self.choose_edit_action(13)  # Delete 中 to the right.
        self.send(ENTER * 3, 0.7)  # Empty no-ops must retain the Undo history.
        self.choose_edit_action(3)
        self.send(ENTER)  # Undo 中, then a.
        self.close_editor()
        state = self.state()
        self.assertEqual(state['buffer'], 'a中')
        self.assertEqual(state['cursor'], 1)

    def test_back_from_repeated_edit_returns_to_main_without_reverting(self):
        self.stage_fixture_buffer('print alpha beta')
        self.menu('delete_word', stay_open=True)
        output = self.send(BACK, 0.35)
        self.assertIn('命令選單：'.encode(), output)
        self.close_editor()
        self.assertEqual(self.state()['buffer'], 'print alpha ')

    def test_editor_session_is_private_cleans_up_and_does_not_execute_text(self):
        marker = self.base / 'must-not-exist'
        buffer = 'print $(touch ' + str(marker) + ') tail'
        self.stage_fixture_buffer(buffer)
        self.menu('delete_word', stay_open=True)
        sessions = list(self.sessiontemp.rglob('state.json'))
        self.assertEqual(len(sessions), 1)
        session = sessions[0]
        self.assertEqual(session.stat().st_mode & 0o777, 0o600)
        self.assertEqual(session.parent.stat().st_mode & 0o777, 0o700)
        self.close_editor()
        self.assertFalse(session.exists())
        self.assertFalse(marker.exists())
        self.assertEqual(self.state()['buffer'], buffer[:-len('tail')])

    def test_snippet_insertion_uses_visible_grapheme_cursor_position(self):
        buffer = 'print "👨‍👩‍👧‍👦é尾"'
        command = 'print "👨‍👩‍👧‍👦é追加尾"'
        with sqlite3.connect(self.historydb) as db:
            db.execute('INSERT INTO history (command_line, cwd, exit_status) VALUES (?, ?, ?)', (command, str(self.cwd), 0))
        self.stage_fixture_buffer(buffer)
        self.send(LEFT * 2)
        before = self.state()
        self.assertEqual(before['cursor'], 9)
        self.menu('snippets')
        self.choose()
        state = self.state()
        self.assertEqual(state['buffer'], command)
        self.assertEqual(state['cursor'], 11)
        self.menu('undo')
        self.assertEqual(self.state(), before)

    def install_test_editor(self, exit_code=0):
        """Stand-in nvim records its input/TTYs and writes a multiline edit."""
        bindir = self.base / "bin"
        bindir.mkdir()
        self.editorlog = self.base / "editor.json"
        editor = bindir / "nvim"
        editor.write_text(
            f"#!{sys.executable}\n"
            "import json, os, pathlib, sys\n"
            "file = pathlib.Path(sys.argv[-1])\n"
            f"pathlib.Path({str(self.editorlog)!r}).write_text(json.dumps({{"
            "'file': str(file), 'input': file.read_text(), "
            "'tty': [os.isatty(fd) for fd in range(3)]}))\n"
            "file.write_text('print EDITED\\nprint SECOND\\n\\n')\n"
            f"sys.exit({exit_code})\n"
        )
        editor.chmod(0o700)
        self.send(f"$env.PATH = ($env.PATH | prepend {literal(bindir)})")
        self.send(ENTER)

    def test_nvim_menu_edits_without_executing_and_can_undo(self):
        self.install_test_editor()
        self.send('print "中文 original"')
        self.send(LEFT * 3)
        before = self.state()
        self.menu("edit")
        self.assertEqual(self.state()["buffer"], "print EDITED\nprint SECOND\n")
        log = json.loads(self.editorlog.read_text())
        self.assertEqual(log["input"], before["buffer"])
        self.assertEqual(log["tty"], [True, True, True])
        self.assertFalse(Path(log["file"]).exists())
        self.menu("undo")
        self.assertEqual(self.state(), before)

    def test_nvim_failure_keeps_original_buffer_and_cleans_tempfile(self):
        self.install_test_editor(exit_code=1)
        self.send('print "keep this"')
        self.send(LEFT * 2)
        before = self.state()
        self.menu("edit")
        self.assertEqual(self.state(), before)
        log = json.loads(self.editorlog.read_text())
        self.assertFalse(Path(log["file"]).exists())

    def test_nvim_can_start_with_empty_commandline(self):
        self.install_test_editor()
        self.menu("edit")
        self.assertEqual(json.loads(self.editorlog.read_text())["input"], "")
        self.assertEqual(self.state()["buffer"], "print EDITED\nprint SECOND\n")

    def test_all_history_fuzzy_query_accepts_spaces_and_backspace(self):
        self.menu("history_all")
        # Neither token is a contiguous substring; Space edits the query and
        # Backspace removes the deliberate typo instead of leaving the picker.
        self.send("rnt FRSTx")
        self.send(BACK)
        self.send(ENTER)
        self.assertEqual(self.state()["buffer"], "print FIRST\nprint SECOND")

    def test_all_history_fuzzy_cancel_preserves_buffer_and_cursor(self):
        self.send('print "中文 tail"')
        self.send(LEFT * 3)
        before = self.state()
        self.menu("history_all")
        self.send("no matching command")
        self.send(ESC)
        self.assertEqual(self.state(), before)

    def test_history_defaults_local_and_can_expand_when_no_matches(self):
        self.menu("history_here")
        self.send("OTHER")
        self.send(RIGHT, 0.35)
        self.send(ENTER)
        self.assertEqual(self.state()["buffer"], "print OTHER")

    def test_history_scope_switch_preserves_fuzzy_query_in_both_directions(self):
        self.menu("history_here")
        self.send("FRST")
        self.send(RIGHT, 0.35)
        self.send(LEFT, 0.35)
        self.send(RIGHT, 0.35)
        self.send(ENTER)
        self.assertEqual(self.state()["buffer"], "print FIRST\nprint SECOND")

    def test_empty_local_history_can_switch_to_global(self):
        self.send(f"cd {literal(self.child)}")
        self.send(ENTER)
        self.menu("history_here")
        self.send("OTHER")
        self.send(RIGHT, 0.35)
        self.send(ENTER)
        self.assertEqual(self.state()["buffer"], "print OTHER")

    def test_history_status_filter_preserves_query_and_scope(self):
        self.menu("history_here")
        self.send("build")
        self.send(TAB, 0.35)  # Success: no matches.
        self.send(RIGHT, 0.35)
        self.send(TAB, 0.35)  # Failed: retains the query and global scope.
        self.send(ENTER)
        self.assertEqual(self.state()["buffer"], "go build ./...")

    def test_file_browser_stages_nvim_and_handles_quoted_filename(self):
        self.install_test_editor()
        target = self.child / "file 'quote' $(literal).txt"
        target.write_text("ORIGINAL FILE")
        self.menu("files")
        self.choose()  # Current-directory browser.
        self.choose(1)  # Child directory.
        self.choose(1)  # File, after '..'.
        state = self.state()
        self.assertTrue(state["buffer"].startswith("^nvim "), state)
        self.assertEqual(target.read_text(), "ORIGINAL FILE")
        self.send(ENTER)
        log = self.wait_for_json(self.editorlog)
        self.assertEqual(log["file"], str(target))
        self.assertEqual(log["input"], "ORIGINAL FILE")

    def test_file_tab_switch_preserves_directory_and_query_even_without_matches(self):
        target = self.child / "needle 'quote' $(literal) 中文.txt"
        target.touch()
        self.menu('files')
        self.choose()  # Browser.
        self.choose(1)  # Child directory.
        self.send(TAB, 0.35)
        self.send('needle')
        self.send(TAB, 0.35)
        self.choose(1)  # Retained child directory: select its file.
        command = self.state()['buffer'].replace('^nvim ', 'echo ', 1)
        result = subprocess.run([NU, '-n', '-c', command + ' | to json'],
                                text=True, capture_output=True, check=True)
        self.assertEqual(json.loads(result.stdout), ['--', str(target)])
        self.menu('files')
        self.choose()
        self.send(TAB, 0.35)
        self.send('needle-no-match')
        self.send(TAB, 0.35)  # No selected row; switch must still work.
        self.send(TAB, 0.35)  # Search text is restored.
        self.send(BACK * len('-no-match'))
        self.send(ENTER)
        command = self.state()['buffer'].replace('^nvim ', 'echo ', 1)
        result = subprocess.run([NU, '-n', '-c', command + ' | to json'],
                                text=True, capture_output=True, check=True)
        self.assertEqual(json.loads(result.stdout), ['--', str(target)])
        self.assertEqual(self.state()['pwd'], str(self.cwd))

    def test_file_tab_switch_empty_project_and_cancel_preserve_commandline(self):
        (self.cwd / 'ordinary-file').unlink()
        self.send('print 中文')
        self.send(LEFT)
        before = self.state()
        self.menu('files')
        self.choose()
        self.send(TAB, 0.35)  # Empty project search.
        self.send(TAB, 0.35)  # Back to browser.
        self.choose(1)  # Navigate into the child, not a launcher/menu row.
        self.send(TAB, 0.35)
        self.send(TAB, 0.35)
        self.send(ESC, 0.35)
        self.assertEqual(self.state(), before)

    def test_project_menu_stages_go_command_without_running_it(self):
        (self.cwd / "go.mod").write_text("module example.test/project\n")
        self.send(f"cd {literal(self.child)}")
        self.send(ENTER)
        self.menu("project")
        self.choose(1)  # Go run, after recent commands.
        state = self.state()
        self.assertEqual(state["pwd"], str(self.child))
        self.assertIn("^go", state["buffer"])
        self.assertTrue(state["buffer"].startswith("cd "), state)

    def test_project_recent_menu_includes_failed_build_for_retry(self):
        (self.cwd / "go.mod").write_text("module example.test/project\n")
        self.menu("project")
        self.choose()  # Recent project commands.
        self.send(ENTER)
        self.assertEqual(self.state()["buffer"], "go build ./...")

    def test_git_menu_stages_status_then_executes_on_next_enter(self):
        subprocess.run(["git", "init", "--initial-branch=main", str(self.cwd)], check=True, capture_output=True)
        self.menu("git")
        self.choose()
        state = self.state()
        self.assertTrue(state["buffer"].startswith("^git "), state)
        self.assertIn("--no-pager", state["buffer"])
        self.assertIn("status", state["buffer"])
        self.assertIn(b"main", self.send(ENTER))
        self.assertEqual(self.state()["buffer"], "")

    def test_git_outside_repository_returns_to_menu_preserving_input(self):
        self.send('print "中文 tail"')
        self.send(LEFT * 3)
        before = self.state()
        output = self.menu("git")
        self.assertIn("目前目錄不是 Git 專案".encode(), output)
        self.assertNotIn(b"fatal:", output)
        self.assertNotIn(b"Error:", output)
        self.send(ESC)
        self.assertEqual(self.state(), before)

    def test_git_menu_from_subdirectory_uses_repository_root(self):
        subprocess.run(["git", "init", "--initial-branch=main", str(self.cwd)], check=True, capture_output=True)
        self.send(f"cd {literal(self.child)}")
        self.send(ENTER)
        self.menu("git")
        self.choose()
        state = self.state()
        self.assertIn(str(self.cwd), state["buffer"])
        self.assertEqual(state["pwd"], str(self.child))
        self.assertIn(b"main", self.send(ENTER))

    def test_tmux_menu_stages_target_and_does_not_switch_during_discovery(self):
        bindir = self.base / "bin"
        bindir.mkdir()
        log = self.base / "tmux.json"
        stub = bindir / "tmux"
        stub.write_text(
            f"#!{sys.executable}\nimport sys,json,pathlib\n"
            f"pathlib.Path({str(log)!r}).write_text(json.dumps(sys.argv[1:]))\n"
            "if sys.argv[1]=='list-panes': print('$1\\t@2\\t%3\\tworkspace:0.0 editor')\n"
        )
        stub.chmod(0o700)
        self.send(f"$env.PATH = ($env.PATH | prepend {literal(bindir)})")
        self.send(ENTER)
        self.menu("tmux")
        self.send(ENTER)
        self.assertEqual(json.loads(log.read_text())[0], "list-panes")
        self.assertIn("select-pane", self.state()["buffer"])
        self.send(ENTER)
        self.assertIn("%3", self.wait_for_json(log, lambda args: "%3" in args))

    def test_launcher_and_picker_cancel_preserve_unicode_buffer_and_cursor(self):
        self.send('print "中文 tail"')
        self.send(LEFT * 3)
        before = self.state()
        self.send(ESC)
        self.send(ESC)
        self.assertEqual(self.state(), before)
        self.menu()
        fcntl.ioctl(self.fd, termios.TIOCSWINSZ, struct.pack("HHHH", 12, 45, 0, 0))
        self.read()
        self.send(ESC)
        self.assertEqual(self.state(), before)

    def test_clear_with_tab_navigation_and_restore(self):
        self.send('print "keep this"')
        self.send(ESC)
        for _ in range(16):
            self.send(TAB, 0.03)
        self.send(ENTER)
        self.send(TAB * 2)
        self.send(ENTER)
        self.assertEqual(self.state()["buffer"], "")
        self.menu("undo")
        self.assertEqual(self.state()["buffer"], 'print "keep this"')

    def test_history_picker_preserves_multiline_command(self):
        self.menu("history_here")
        self.send(ENTER)
        self.assertEqual(self.state()["buffer"], "print FIRST\nprint SECOND")

    def test_favorite_staged_then_run_and_controller_undo(self):
        self.send("print original")
        self.menu()
        self.send(ENTER)
        self.assertEqual(self.state()["buffer"], "print TEST_EXECUTED")
        self.menu("undo")
        self.assertEqual(self.state()["buffer"], "print original")
        self.menu()
        self.send(ENTER)
        self.assertEqual(self.state()["buffer"], "print TEST_EXECUTED")
        output = self.send(ENTER)
        self.assertIn(b"TEST_EXECUTED\r\n", output)
        self.assertEqual(self.state()["buffer"], "")

    def test_add_remove_favorite_and_backspace_to_main(self):
        self.send("print SAVED")
        self.menu("add_favorite")
        self.assertIn("print SAVED", self.favorites.read_text())
        self.menu()
        self.send(BACK)
        self.send(ESC)
        self.assertEqual(self.state()["buffer"], "print SAVED")
        self.menu("remove_favorite")
        self.send(TAB)
        self.send(ENTER)
        self.send(ESC)
        self.assertNotIn("print SAVED", self.favorites.read_text())

    def test_main_backspace_preserves_buffer_and_cursor(self):
        self.send('print "中文 tail"')
        self.send(LEFT * 3)
        before = self.state()
        self.send(ESC)
        self.send(BACK)
        self.assertEqual(self.state(), before)

    def test_fuzzy_empty_backspace_returns_one_level_at_a_time(self):
        self.menu("files")
        self.choose(1)  # Project file search.
        self.send(BACK)  # Files menu.
        self.send(BACK)  # Main menu.
        self.choose()  # Favorites.
        self.send(ENTER)
        self.assertEqual(self.state()["buffer"], "print TEST_EXECUTED")

    def test_fuzzy_backspace_deletes_last_unicode_character_without_returning(self):
        self.menu("files")
        self.choose(1)
        self.send("中x")
        self.send(BACK)
        self.send(BACK)  # Query becomes empty; stay in the file picker.
        self.send(ENTER)
        self.assertIn(str(self.cwd / "ordinary-file"), self.state()["buffer"])

    def test_fuzzy_backspace_deletes_space_without_returning(self):
        self.menu("files")
        self.choose(1)
        self.send(" ")
        self.send(BACK)
        self.send(ENTER)
        self.assertIn(str(self.cwd / "ordinary-file"), self.state()["buffer"])

    def test_fuzzy_backspace_at_query_start_keeps_nonempty_query(self):
        self.menu("files")
        self.choose(1)
        self.send("ordnry")
        self.send(b"\x01")  # Ctrl-A: cursor at the start of a nonempty query.
        self.send(BACK)
        self.send(ENTER)
        self.assertIn(str(self.cwd / "ordinary-file"), self.state()["buffer"])

    def test_history_backspace_deletes_last_character_without_returning(self):
        self.menu("history_here")
        self.send("x")
        self.send(BACK)
        self.send(ENTER)
        self.assertEqual(self.state()["buffer"], "print FIRST\nprint SECOND")

    def test_empty_history_backspace_returns_even_without_selected_item(self):
        self.send(f"cd {literal(self.child)}")
        self.send(ENTER)
        self.menu("history_here")
        self.send(BACK)
        self.choose()  # Favorites from main.
        self.send(ENTER)
        self.assertEqual(self.state()["buffer"], "print TEST_EXECUTED")

    def test_history_backspace_return_does_not_restore_old_scope_query(self):
        self.menu("history_here")
        self.send("FRST")
        self.send(RIGHT, 0.35)  # Persist query while changing scope.
        for _ in range(4):
            self.send(BACK)
        self.send(BACK)  # Empty query: return to main.
        self.choose(1)  # History again.
        self.send("build")
        self.send(ENTER)
        self.assertEqual(self.state()["buffer"], "go build ./...")

    def test_project_file_fzf_search_preserves_literal_path(self):
        target = self.child / "needle one 'quote' $(literal)\nfile.txt"
        target.touch()
        self.menu("files")
        self.choose(1)
        self.send("ndle onex")
        self.send(BACK)
        self.send(ENTER)
        state = self.state()
        # Decode the staged arguments without opening an editor.
        self.assertTrue(state["buffer"].startswith("^nvim "), state)
        command = state["buffer"].replace("^nvim ", "echo ", 1)
        result = subprocess.run([NU, "-n", "-c", command + " | to json"],
                                text=True, capture_output=True, check=True)
        self.assertEqual(json.loads(result.stdout), ["--", str(target)])
        self.send(LEFT * 3)
        before = self.state()
        self.menu("files")
        self.choose(1)
        self.send("no-matching-file")
        self.send(ESC)
        self.assertEqual(self.state(), before)

    def test_git_fzf_file_and_branch_selection(self):
        def git(*args):
            return subprocess.run(["git", "-C", str(self.cwd), *args],
                                  check=True, capture_output=True, text=True)
        git("init", "--initial-branch=main")
        git("-c", "user.name=Controller Test", "-c", "user.email=test@example.invalid",
            "commit", "--allow-empty", "-m", "fixture")
        git("branch", "topic-test")
        self.menu("git")
        self.choose(5)  # Changed files, including untracked files.
        self.send("ordnry")
        self.send(ENTER)
        self.assertIn(str(self.cwd / "ordinary-file"), self.state()["buffer"])
        self.send(b"\x03")
        self.menu("git")
        self.choose(6)  # Local branches.
        self.send("tpctst")
        self.send(ENTER)
        self.assertIn("topic-test", self.state()["buffer"])
        self.assertEqual(git("branch", "--show-current").stdout.strip(), "main")
        self.send(ENTER)
        self.assertEqual(git("branch", "--show-current").stdout.strip(), "topic-test")

    def test_remove_favorite_uses_index_with_duplicate_labels(self):
        self.favorites.write_text('[{label: "same", command: "print FIRST"} '
                                  '{label: "same", command: "print SECOND"}]')
        self.menu("remove_favorite")
        self.choose(1)
        self.send(ESC)
        self.assertIn("print FIRST", self.favorites.read_text())
        self.assertNotIn("print SECOND", self.favorites.read_text())

    def test_snippet_inserts_partial_argument_without_executing(self):
        self.send("go bu")
        self.menu("snippets")
        self.send("ild")
        self.send(ENTER)
        state = self.state()
        self.assertEqual(state["buffer"], "go build ./...")
        self.assertEqual(state["cursor"], len("go build ./..."))
        self.menu("undo")
        self.assertEqual(self.state()["buffer"], "go bu")

    def test_snippet_inserts_at_unicode_cursor_preserving_right_and_undo(self):
        buffer = 'print "中文" | str length'
        right = '" | str length'
        self.send(buffer)
        self.send(LEFT * len(right))
        before = self.state()
        self.menu("snippets")
        self.send(ENTER)
        state = self.state()
        self.assertEqual(state["buffer"], 'print "中文追加" | str length')
        self.assertEqual(state["cursor"], len('print "中文追加'))
        self.menu("undo")
        self.assertEqual(self.state(), before)

    def test_snippet_local_multiline_default_and_global_fuzzy_search(self):
        self.send("print ")
        self.menu("snippets")
        self.send(ENTER)
        self.assertEqual(self.state()["buffer"], "print FIRST\nprint SECOND")
        self.send(b"\x03")
        self.send("print ")
        self.menu("snippets")
        self.send("OTHRx")
        self.send(BACK)
        self.send(ENTER)
        self.assertEqual(self.state()["buffer"], "print OTHER")

    def test_snippet_cancel_preserves_buffer_and_cursor(self):
        self.send("go bu # keep 中文")
        self.send(LEFT * len(" # keep 中文"))
        before = self.state()
        self.menu("snippets")
        self.send("no matching snippet")
        self.send(ESC)
        self.assertEqual(self.state(), before)

    def test_snippet_empty_or_unmatched_prefix_returns_to_main(self):
        for buffer in ["", "never-used-command "]:
            self.send(buffer)
            before = self.state()
            output = self.menu("snippets")
            self.assertIn("找不到可接續的歷史片段".encode(), output)
            self.send(ESC)
            self.assertEqual(self.state(), before)
            self.send(b"\x03")

    def test_directory_navigation_backspace_and_quoted_path(self):
        self.menu("directories")
        self.send(DOWN * 4)
        self.send(RIGHT)
        self.send(BACK)
        self.send(DOWN * 4)
        self.send(ENTER)
        self.send(ENTER)
        state = self.state()
        self.assertEqual(state["pwd"], str(self.cwd))
        self.assertTrue(state["buffer"].startswith("cd "), state)
        self.send(ENTER)
        self.assertEqual(self.state()["pwd"], str(self.child))

    def test_completion_escape_enter_and_multiline_input(self):
        self.send("gamepad-test-")
        self.send(TAB)
        output = self.send(ESC)
        self.assertNotIn("收藏命令".encode(), output)
        self.assertEqual(self.state()["buffer"], "gamepad-test-")
        self.send(TAB)
        self.send(DOWN)
        self.send(ENTER)
        self.assertTrue(self.state()["buffer"].startswith("gamepad-test-"))
        self.send(b"\x03")
        self.send("(print MULTILINE")
        self.send(ENTER)
        self.assertIn("\n", self.state()["buffer"])
        self.send(")")
        self.assertIn(b"MULTILINE\r\n", self.send(ENTER))

    def test_history_order_filter_and_multiline_are_preserved(self):
        code = f'''source {literal(SOURCE)}
        [
          {{command: "print old", exit_status: 0, cwd: $env.PWD}}
          {{command: "print other", exit_status: 0, cwd: /other}}
          {{command: "print failed", exit_status: 1, cwd: $env.PWD}}
          {{command: "print old", exit_status: 0, cwd: $env.PWD}}
          {{command: "print one\\nprint two", exit_status: 0, cwd: $env.PWD}}
        ] | menu history-items --here --status success | get command | to json'''
        result = subprocess.run([NU, "-n", "-c", code], text=True, capture_output=True, check=True)
        self.assertEqual(json.loads(result.stdout), ["print one\nprint two", "print old"])


if __name__ == "__main__":
    unittest.main(verbosity=2)

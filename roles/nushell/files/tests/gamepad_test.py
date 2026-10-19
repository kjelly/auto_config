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
import shutil
import signal
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
        self.statefile = self.base / "state.json"
        config = self.base / "test.nu"
        config.write_text("\n".join([
            "$env.config.show_banner = false",
            "$env.PROMPT_COMMAND = {|| 'TEST> '}",
            "$env.PROMPT_COMMAND_RIGHT = ''",
            f"$env.GAMEPAD_FAVORITES_FILE = {literal(self.favorites)}",
            f"cd {literal(self.cwd)}",
            'let test_history_directory = $env.PWD',
            'def history [--long] { [{command: \'print "中文追加" | str length\', exit_status: 0, cwd: $test_history_directory} {command: "go build ./...", exit_status: 1, cwd: $test_history_directory} {command: "print FIRST\\nprint SECOND", exit_status: 0, cwd: $test_history_directory} {command: "print OTHER", exit_status: 0, cwd: /elsewhere}] }',
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
            os.execv(NU, [NU, "-n", "--no-history", "-e", f"source {literal(config)}"])
        fcntl.ioctl(self.fd, termios.TIOCSWINSZ, struct.pack("HHHH", 32, 100, 0, 0))
        self.output = b""
        self.read(0.6)
        self.assertIn(b"TEST>", self.output)

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

    def menu(self, action="favorites"):
        if action == "history_all":
            self.menu("history_here")
            return self.send(RIGHT, 0.35)
        management = {"add_favorite": 0, "remove_favorite": 1, "clear": 2, "undo": 3}
        if action in management:
            self.menu("manage")
            return self.choose(management[action])
        index = {"favorites": 0, "history_here": 1, "snippets": 2, "project": 3,
                 "files": 4, "git": 5, "tmux": 6, "directories": 7,
                 "edit": 8, "manage": 9}[action]
        self.send(ESC)
        return self.choose(index)

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
        for _ in range(9):
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
        ] | gamepad history-items --here --status success | get command | to json'''
        result = subprocess.run([NU, "-n", "-c", code], text=True, capture_output=True, check=True)
        self.assertEqual(json.loads(result.stdout), ["print one\nprint two", "print old"])


if __name__ == "__main__":
    unittest.main(verbosity=2)

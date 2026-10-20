"""Inspect rendered terminal cells using an isolated tmux server.

Run with local Unix socket permission:
GAMEPAD_TEST_REAL_TMUX=1 python3 tests/gamepad_render_test.py
"""
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import time
import unittest

from gamepad_test import NU, SOURCE, literal


@unittest.skipUnless(os.environ.get("GAMEPAD_TEST_REAL_TMUX") and shutil.which("tmux"),
                     "requires tmux and local Unix socket permission")
class RenderTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix="gamepad-render-")
        self.base = Path(self.temp.name)
        self.env = dict(os.environ, TMUX_TMPDIR=str(self.base))
        self.env.pop("TMUX", None)
        self.command = [shutil.which("tmux"), "-L", "render-test", "-f", "/dev/null"]
        self.addCleanup(self.temp.cleanup)
        self.addCleanup(lambda: subprocess.run(self.command + ["kill-server"],
                                               env=self.env, capture_output=True))
        (self.base / "selected.txt").touch()
        config = self.base / "test.nu"
        config.write_text("\n".join([
            "$env.config.show_banner = false",
            "$env.PROMPT_COMMAND = {|| \"TOP\\nTEST> \"}",
            "$env.PROMPT_COMMAND_RIGHT = ''",
            "$env.PROMPT_INDICATOR = ''",
            f"$env.GAMEPAD_TASK_CONFIG = {literal(config)}",
            f"$env.GAMEPAD_TASK_ENV_CONFIG = {literal(self.base / 'env.nu')}",
            f"cd {literal(self.base)}",
            'def history [--long] { [{command: "go test -race ./...", cwd: $env.PWD}] }',
            f"source {literal(SOURCE)}",
        ]))
        (self.base / 'env.nu').write_text('')
        self.tmux("new-session", "-d", "-x", "100", "-y", "32", "-s", "test",
                  NU, "-n", "--no-history", "-e", f"source {literal(config)}")
        self.wait_for("TEST>")

    def tmux(self, *args):
        result = subprocess.run(self.command + list(args), env=self.env,
                                text=True, capture_output=True)
        self.assertEqual(result.returncode, 0, result.stderr)
        return result.stdout

    def screen(self):
        return self.tmux("capture-pane", "-p").rstrip()

    def wait_for(self, text, absent=()):
        deadline = time.monotonic() + 4
        while time.monotonic() < deadline:
            screen = self.screen()
            if text in screen and all(part not in screen for part in absent):
                return screen
            time.sleep(0.04)
        self.fail(f"Missing {text!r}:\n{self.screen()}")

    def open_menu(self, index):
        self.tmux("send-keys", "Escape")
        self.wait_for("命令選單：")
        self.tmux("send-keys", *(["Down"] * index), "Enter")

    def assert_no_launcher_residue(self, screen):
        self.assertNotRegex(screen, r"(?m)^\d+: ", screen)
        self.assertNotIn("Page 1: records", screen)
        self.assertNotIn("__nu_gamepad__:", screen)
        self.assertNotIn("管理收藏與命令列", screen)
        self.assertNotIn("命令選單：", screen)

    def test_plain_picker_preserves_earlier_output_without_launcher_residue(self):
        self.tmux("send-keys", "-l", "print SAVED_OUTPUT")
        self.tmux("send-keys", "Enter")
        self.wait_for("SAVED_OUTPUT\n")
        self.open_menu(4)
        screen = self.wait_for("瀏覽目前目錄與子目錄")
        self.assert_no_launcher_residue(screen)
        self.assertIn("SAVED_OUTPUT", screen)
        self.tmux("send-keys", "Down", "Enter")
        screen = self.wait_for("selected.txt")
        self.assert_no_launcher_residue(screen)
        self.tmux("send-keys", "BSpace")
        screen = self.wait_for("瀏覽目前目錄與子目錄", absent=("selected.txt",))
        self.assert_no_launcher_residue(screen)
        self.tmux("send-keys", "Escape")
        screen = self.wait_for("TEST>", absent=("selected.txt", "瀏覽目前目錄與子目錄"))
        self.assert_no_launcher_residue(screen)
        self.assertNotIn("selected.txt", screen)

    def test_fuzzy_snippet_picker_and_return_to_prompt(self):
        self.tmux("send-keys", "-l", "go test")
        self.open_menu(2)
        screen = self.wait_for("-race ./...")
        self.assert_no_launcher_residue(screen)
        self.assertRegex(screen, r"(?m)^ {0,2}輸入文字搜尋 ·", screen)
        self.tmux("send-keys", "Enter")
        screen = self.wait_for("TEST> go test -race ./...")
        self.assert_no_launcher_residue(screen)
        self.assertNotIn("插入歷史片段：", screen)

    def test_file_tab_mode_hints_and_query_on_narrow_screen(self):
        self.tmux('resize-window', '-x', '45', '-y', '20')
        self.open_menu(4)
        self.wait_for('瀏覽目前目錄與子目錄')
        self.tmux('send-keys', 'Enter')
        screen = self.wait_for('檔案：目錄瀏覽')
        self.assertIn('Tab 切換', screen)
        self.assert_no_launcher_residue(screen)
        self.tmux('send-keys', 'Tab')
        self.wait_for('檔案：專案搜尋', absent=('檔案：目錄瀏覽',))
        self.tmux('send-keys', '-l', 'selected-no-match')
        self.wait_for('selected-no-match')
        self.tmux('send-keys', 'Tab')
        self.wait_for('檔案：目錄瀏覽', absent=('檔案：專案搜尋',))
        self.tmux('send-keys', 'Tab')
        screen = self.wait_for('selected-no-match', absent=('檔案：目錄瀏覽',))
        self.assertIn('檔案：專案搜尋', screen)
        self.assertIn('Tab 切換', screen)
        self.assert_no_launcher_residue(screen)
        self.tmux('send-keys', 'Escape')
        self.wait_for('TEST>', absent=('檔案：專案搜尋',))

    def test_fzf_browser_does_not_leave_launcher_rows(self):
        self.open_menu(7)
        screen = self.wait_for("使用此目錄")
        self.assert_no_launcher_residue(screen)
        self.tmux("send-keys", "Escape")
        screen = self.wait_for("TEST>", absent=("使用此目錄",))
        self.assert_no_launcher_residue(screen)
        self.assertNotIn("使用此目錄", screen)

    def test_navigation_hints_visible_in_plain_search_and_narrow_menus(self):
        for width in [100, 45]:
            with self.subTest(width=width):
                self.tmux('resize-window', '-x', str(width), '-y', '24')
                self.open_menu(4)
                screen = self.wait_for('Shift-Tab', absent=('命令選單：',))
                self.assertIn('Home/End 首末項', screen)
                self.assertIn('←→ / PgUp/PgDn 分頁', screen)
                self.assert_no_launcher_residue(screen)
                self.tmux('send-keys', 'Escape')
                self.wait_for('TEST>', absent=('Shift-Tab',))
                self.tmux('send-keys', '-l', 'go test')
                self.open_menu(2)
                screen = self.wait_for('Shift-Tab', absent=('命令選單：',))
                self.assertIn('Home/End 搜尋首尾', screen)
                self.assertIn('PgUp/PgDn 分頁', screen)
                self.assertNotIn('←→ / PgUp/PgDn', screen)
                self.assert_no_launcher_residue(screen)
                self.tmux('send-keys', 'Escape')
                self.wait_for('TEST>', absent=('Shift-Tab',))
                self.tmux('send-keys', 'C-c')

    def test_continuous_edit_preview_and_repeated_enter_on_narrow_screen(self):
        for width in [100, 45]:
            with self.subTest(width=width):
                self.tmux('resize-window', '-x', str(width), '-y', '16')
                self.tmux('send-keys', '-l', 'print alpha beta gamma')
                self.open_menu(16)
                screen = self.wait_for('編輯可連按 Enter')
                self.assertIn('命令：', screen)
                self.assertIn('▏', screen)
                self.assert_no_launcher_residue(screen)
                self.tmux('send-keys', *(['Down'] * 6), 'Enter')
                self.wait_for('alpha beta ▏')
                self.tmux('send-keys', 'Enter')
                screen = self.wait_for('print alpha ▏')
                self.assertIn('編輯可連按 Enter', screen)
                self.assert_no_launcher_residue(screen)
                self.tmux('send-keys', 'Escape')
                self.wait_for('TEST> print alpha', absent=('編輯可連按 Enter',))
                self.tmux('send-keys', 'C-c')

    def test_narrow_terminal_with_multiline_prompt(self):
        self.tmux("resize-window", "-x", "45", "-y", "16")
        self.open_menu(4)
        screen = self.wait_for("瀏覽目前目錄與子目錄")
        self.assert_no_launcher_residue(screen)

        self.tmux("send-keys", "Escape")
        screen = self.wait_for("TEST>", absent=("瀏覽目前目錄與子目錄",))
        self.assert_no_launcher_residue(screen)
        self.assertNotIn("瀏覽目前目錄與子目錄", screen)
        self.tmux("send-keys", "-l", "go test")
        self.open_menu(2)
        screen = self.wait_for("-race ./...")
        self.assert_no_launcher_residue(screen)
        self.assertRegex(screen, r"(?m)^ {0,2}輸入文字搜尋 ·", screen)
        self.tmux("send-keys", "Escape")
        screen = self.wait_for("TEST> go test", absent=("-race ./...",))
        self.assert_no_launcher_residue(screen)


    def test_task_menu_stages_launch_views_output_and_stages_rerun(self):
        self.tmux('send-keys', '-l', 'print TASK_MENU_OUTPUT')
        self.open_menu(15)
        self.wait_for('目前指令在獨立 pane 執行')
        self.tmux('send-keys', 'Enter')
        self.wait_for('TEST> menu task-start')
        self.assertEqual(len(self.tmux('list-panes', '-a').splitlines()), 1)
        self.tmux('send-keys', 'Enter')
        self.wait_for('任務已在')
        self.open_menu(15)
        deadline = time.monotonic() + 4
        while '已結束' not in self.screen() and time.monotonic() < deadline:
            self.tmux('send-keys', 'End', 'Enter')  # Refresh task status.
            time.sleep(0.05)
        self.wait_for('已結束')
        self.tmux('send-keys', 'Down', 'Enter')
        self.wait_for('查看輸出')
        self.tmux('send-keys', 'Enter')
        screen = self.wait_for('↻ 重新整理輸出')
        self.assertIn('TASK_MENU_OUTPUT', screen)
        self.assert_no_launcher_residue(screen)
        self.tmux('send-keys', 'BSpace')
        self.wait_for('查看輸出')
        self.tmux('send-keys', 'Down', 'Down', 'Enter')
        self.wait_for('TEST> menu task-rerun')


if __name__ == "__main__":
    unittest.main(verbosity=2)

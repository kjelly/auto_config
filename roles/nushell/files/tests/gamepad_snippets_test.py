"""History-derived insertion candidates; never load or execute real history.

Run: python3 tests/gamepad_snippets_test.py
"""
import json
from pathlib import Path
import subprocess
import tempfile
import unittest

from gamepad_test import NU, SOURCE, literal


class SnippetTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix="gamepad-snippets-")
        self.cwd = Path(self.temp.name)

    def tearDown(self):
        self.temp.cleanup()

    def row(self, command, cwd=None, **fields):
        return dict(command=command, cwd=str(cwd or self.cwd), **fields)

    def items(self, rows, buffer, cursor=None):
        if cursor is None:
            cursor = len(buffer)
        code = (f"source {literal(SOURCE)}; "
                f"{json.dumps(rows, ensure_ascii=False)} | "
                f"gamepad snippet-items {literal(buffer)} {cursor} | to json")
        result = subprocess.run([NU, "-n", "-c", code], cwd=self.cwd,
                                text=True, capture_output=True)
        self.assertEqual(result.returncode, 0, result.stderr)
        return json.loads(result.stdout)

    def test_local_priority_recency_and_deduplication(self):
        rows = [self.row("go test -race ./..."),
                self.row("go test -count=1 ./..."),
                self.row("go test -json ./...", cwd="/elsewhere"),
                self.row("go test -race ./...", cwd="/elsewhere")]
        items = self.items(rows, "go test")
        self.assertEqual([row["snippet"] for row in items],
                         [" -count=1 ./...", " -race ./...", " -json ./..."])
        self.assertEqual([row["here"] for row in items], [True, True, False])

    def test_command_boundaries_exclude_other_executables(self):
        rows = [self.row("github list"), self.row("git status"),
                self.row("git"), self.row("git   "), self.row("echo git log")]
        self.assertEqual([row["snippet"] for row in self.items(rows, "git")],
                         [" status"])

    def test_partial_argument_is_completed_by_insertion(self):
        items = self.items([self.row("git log --oneline")], "git lo")
        self.assertEqual(items[0]["snippet"], "g --oneline")

    def test_empty_or_missing_context_does_not_offer_arbitrary_history(self):
        rows = [self.row("git status")]
        for buffer, cursor in [("", 0), ("  \t", 3), ("git", 0), ("go test", 7)]:
            with self.subTest(buffer=buffer, cursor=cursor):
                self.assertEqual(self.items(rows, buffer, cursor), [])

    def test_quotes_interpolation_and_multiline_are_literal(self):
        tail = '\'a b\' "中文" $env.NAME `backtick`\nprint SECOND'
        items = self.items([self.row("echo " + tail)], "echo ")
        self.assertEqual(items[0]["snippet"], tail)

    def test_unicode_cursor_and_shared_right_text(self):
        prefix = 'print "中文é😀'
        right = '" | str length'
        items = self.items([self.row(prefix + "追加" + right)],
                           prefix + right, len(prefix))
        self.assertEqual(items[0]["snippet"], "追加")

    def test_existing_right_text_does_not_filter_valid_candidates(self):
        items = self.items([self.row("go build ./...")], "go bu | print done", 5)
        self.assertEqual(items[0]["snippet"], "ild ./...")

    def test_identical_history_with_right_text_has_nothing_to_insert(self):
        command = "go test | print done"
        self.assertEqual(self.items([self.row(command)], command, 7), [])

    def test_literal_prefix_with_regex_characters_and_pipeline(self):
        prefix = "echo '[a].*' | str "
        rows = [self.row(prefix + "length"), self.row("echo aaaa | str length")]
        self.assertEqual([row["snippet"] for row in self.items(rows, prefix)],
                         ["length"])

    def test_indentation_preserves_original_buffer_whitespace(self):
        items = self.items([self.row("  go test -race ./...")], "\tgo test ")
        self.assertEqual(items[0]["snippet"], "-race ./...")

    def test_failed_history_and_missing_cwd_are_available(self):
        rows = [self.row("go test -race", exit_status=1),
                {"command": "go test -json"}]
        items = self.items(rows, "go test")
        self.assertEqual([row["snippet"] for row in items], [" -race", " -json"])
        self.assertTrue(items[1]["label"].startswith("[全域]"))

    def test_history_is_never_executed(self):
        marker = self.cwd / "UNEXPECTED"
        items = self.items([self.row(f"echo OK; touch {marker}")], "echo ")
        self.assertIn("touch", items[0]["snippet"])
        self.assertFalse(marker.exists())


if __name__ == "__main__":
    unittest.main(verbosity=2)

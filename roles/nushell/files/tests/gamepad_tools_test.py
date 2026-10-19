"""Read-only discovery and staged-command tests using temporary projects.

Run: python3 tests/gamepad_tools_test.py
Real tmux IPC test: GAMEPAD_TEST_REAL_TMUX=1 python3 tests/gamepad_tools_test.py ToolTests.test_real_tmux_discovery
"""
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
import unittest

from gamepad_test import NU, SOURCE, literal


class ToolTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix="gamepad-tools-")
        self.base = Path(self.temp.name)
        self.root = self.base / "project 'quoted' $(literal)"
        self.root.mkdir()
        self.child = self.root / "src"
        self.child.mkdir()
        self.env = dict(os.environ, GIT_CONFIG_NOSYSTEM="1", GIT_CONFIG_GLOBAL="/dev/null")

    def tearDown(self):
        self.temp.cleanup()

    def nu(self, expression, cwd=None, env=None):
        code = f"source {literal(SOURCE)}; {expression} | to json"
        result = subprocess.run([NU, "-n", "-c", code], cwd=cwd or self.root,
                                env=env or self.env, text=True, capture_output=True)
        self.assertEqual(result.returncode, 0, result.stderr)
        return json.loads(result.stdout)

    def git(self, *args):
        return subprocess.run(["git", "-C", str(self.root), *args], env=self.env,
                              text=True, capture_output=True, check=True).stdout

    def repository(self):
        self.git("init", "--initial-branch=main")
        self.git("config", "user.name", "Test")
        self.git("config", "user.email", "test@example.invalid")
        self.git("config", "core.hooksPath", "/dev/null")
        self.git("config", "commit.gpgsign", "false")
        (self.root / ".gitignore").write_text("ignored\n")
        (self.root / "old.txt").write_text("original\n")
        self.git("add", ".")
        self.git("commit", "-m", "fixture")

    def stub(self, name, body):
        bindir = self.base / "bin"
        bindir.mkdir(exist_ok=True)
        executable = bindir / name
        executable.write_text(f"#!{sys.executable}\n" + body)
        executable.chmod(0o700)
        return dict(self.env, PATH=str(bindir) + os.pathsep + self.env["PATH"])

    def test_command_quoting_round_trip(self):
        args = ["-c", "import json,sys; print(json.dumps(sys.argv[1:]))",
                "spaces 'quotes' \"double\" $(literal) `backticks`\n中文"]
        command = self.nu(f"gamepad command python3 {json.dumps(args, ensure_ascii=False)}")
        result = subprocess.run([NU, "-n", "-c", command], env=self.env,
                                text=True, capture_output=True, check=True)
        self.assertEqual(json.loads(result.stdout), args[2:])

    def test_go_command_runs_in_project_root_from_subdirectory(self):
        (self.root / "go.mod").write_text("module example.test/project\n")
        self.assertEqual(self.nu("gamepad project-root", cwd=self.child), str(self.root))
        items = self.nu(f"gamepad project-items {literal(self.root)}", cwd=self.child)
        command = next(item["command"] for item in items if item["label"] == "Go：執行本專案")
        env = self.stub("go", "import os,sys,json\nprint(json.dumps({'cwd':os.getcwd(),'args':sys.argv[1:]}))\n")
        result = subprocess.run([NU, "-n", "-c", command], cwd=self.child,
                                env=env, text=True, capture_output=True, check=True)
        self.assertEqual(json.loads(result.stdout), {"cwd": str(self.root), "args": ["run", "."]})

    def test_just_and_make_discovery_does_not_run_recipes(self):
        (self.root / "justfile").write_text("hello:\n    touch UNEXPECTED\n\n[private]\nhidden:\n    touch UNEXPECTED\n")
        (self.root / "Makefile").write_text("build:\n\ttouch UNEXPECTED\n\ntest:\n\ttouch UNEXPECTED\n")
        just = self.nu(f"gamepad project-tasks {literal(self.root)} just")
        make = self.nu(f"gamepad project-tasks {literal(self.root)} make")
        self.assertEqual([item["label"] for item in just], ["hello"])
        self.assertEqual([item["label"] for item in make], ["build", "test"])
        self.assertFalse((self.root / "UNEXPECTED").exists())

    def test_nur_discovery_uses_project_nurfile(self):
        (self.root / "nurfile").touch()
        log = self.base / "nur-args.json"
        env = self.stub("nur", f"import sys,json,pathlib,os\nassert sys.argv[1:]==['--list','--quiet'], 'unsupported nur flags'\nassert pathlib.Path('nurfile').is_file()\npathlib.Path({str(log)!r}).write_text(json.dumps({{'args':sys.argv[1:],'cwd':os.getcwd()}}))\nprint('build\\ntest')\n")
        result = self.nu(f"let items = (gamepad project-tasks {literal(self.root)} nur); {{items: $items, cwd: $env.PWD}}", cwd=self.child, env=env)
        items = result["items"]
        self.assertEqual([item["label"] for item in items], ["build", "test"])
        self.assertEqual(json.loads(log.read_text()), {"args": ["--list", "--quiet"], "cwd": str(self.root)})
        self.assertEqual(result["cwd"], str(self.child))

    def test_real_nur_lists_root_tasks_without_executing_them(self):
        (self.root / "nurfile").write_text(
            'def "nur controller-build" [] { "unexpected" | save TASK_RAN }\n'
            'def "nur controller-test" [] { "unexpected" | save TASK_RAN }\n'
        )
        (self.child / "nurfile").write_text('def "nur child-only" [] {}\n')
        result = self.nu(
            f"let items = (gamepad project-tasks {literal(self.root)} nur); {{items: $items, cwd: $env.PWD}}",
            cwd=self.child,
        )
        self.assertEqual([item["label"] for item in result["items"]], ["controller-build", "controller-test"])
        self.assertEqual(result["cwd"], str(self.child))
        self.assertFalse((self.root / "TASK_RAN").exists())

    def test_history_status_filters_keep_unknown_only_in_all(self):
        rows = [{"command": "success", "cwd": str(self.root), "exit_status": 0},
                {"command": "failed", "cwd": str(self.root), "exit_status": 1},
                {"command": "interrupted", "cwd": str(self.root), "exit_status": 130},
                {"command": "unknown", "cwd": str(self.root)}]
        fixture = self.base / "history.json"
        fixture.write_text(json.dumps(rows))
        for status, expected in [("all", ["unknown", "interrupted", "failed", "success"]),
                                 ("success", ["success"]), ("failed", ["interrupted", "failed"])]:
            actual = self.nu(f"open {literal(fixture)} | gamepad history-items --here --status {status} | get command")
            self.assertEqual(actual, expected)

    def test_project_history_preserves_cwd_and_excludes_prefix_sibling(self):
        rows = [{"command": "go run .", "cwd": str(self.child), "exit_status": 0},
                {"command": "go build", "cwd": str(self.root) + "-other", "exit_status": 0}]
        fixture = self.base / "history.json"
        fixture.write_text(json.dumps(rows))
        actual = self.nu(f"open {literal(fixture)} | gamepad history-items --project {literal(self.root)}")
        self.assertEqual(len(actual), 1)
        self.assertEqual(actual[0]["cwd"], str(self.child))

    def test_git_files_preserve_renames_newlines_and_untracked_paths(self):
        self.repository()
        renamed = 'new "quoted" $(literal).txt'
        untracked = "two\nlines.txt"
        self.git("mv", "old.txt", renamed)
        (self.root / untracked).write_text("untracked")
        (self.root / "ignored").write_text("ignored")
        changed = self.nu(f"gamepad git-files {literal(self.root)}")
        self.assertEqual(len(changed), 2)
        self.assertTrue(any(renamed in item["label"] for item in changed))
        self.assertTrue(any(untracked in item["label"] for item in changed))
        files = self.nu(f"gamepad project-files {literal(self.root)}")
        names = {item["label"] for item in files}
        self.assertEqual(names, {".gitignore", renamed, untracked})
        self.assertEqual(self.nu("gamepad project-root", cwd=self.child), str(self.root))

    def test_git_branch_command_switches_selected_literal_branch(self):
        self.repository()
        branch = "feature/$literal"
        self.git("branch", branch)
        items = self.nu(f"gamepad git-branches {literal(self.root)}")
        command = next(item["command"] for item in items if item["label"] == branch)
        self.assertEqual(self.git("branch", "--show-current").strip(), "main")
        result = subprocess.run([NU, "-n", "-c", command], env=self.env, text=True, capture_output=True)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(self.git("branch", "--show-current").strip(), branch)

    def test_git_root_returns_null_outside_repository_and_finds_parent(self):
        self.assertIsNone(self.nu("gamepad git-root", cwd=self.child))
        self.repository()
        self.assertEqual(self.nu("gamepad git-root", cwd=self.child), str(self.root))

    def test_git_worktree_is_recognized_from_subdirectory(self):
        self.repository()
        worktree = self.base / "linked 'worktree'"
        self.git("worktree", "add", "-b", "linked", str(worktree))
        nested = worktree / "nested"
        nested.mkdir()
        self.assertEqual(self.nu("gamepad git-root", cwd=nested), str(worktree))
        self.assertTrue((worktree / ".git").is_file())
        files = self.nu(f"gamepad project-files {literal(worktree)}", cwd=nested)
        self.assertIn("old.txt", [item["label"] for item in files])

    def test_all_git_view_commands_execute_against_real_repository(self):
        self.repository()
        (self.root / "old.txt").write_text("changed\n")
        items = self.nu(f"gamepad git-items {literal(self.root)}", cwd=self.child)
        commands = [item["command"] for item in items if "command" in item]
        self.assertEqual(len(commands), 5)
        for command in commands:
            result = subprocess.run([NU, "-n", "-c", command], cwd=self.child,
                                    env=self.env, text=True, capture_output=True)
            self.assertEqual(result.returncode, 0, f"{command}\n{result.stderr}")

    def test_non_git_project_files_excludes_dependency_directories(self):
        (self.child / "normal.txt").touch()
        for name in [".git", "node_modules", "target", "vendor"]:
            (self.root / name).mkdir()
            (self.root / name / "excluded.txt").touch()
        # .git is not a real repository, so remove it before fallback discovery.
        shutil.rmtree(self.root / ".git")
        files = self.nu(f"gamepad project-files {literal(self.root)}")
        self.assertEqual([item["label"] for item in files], ["src/normal.txt"])

    def test_tmux_commands_target_ids_and_do_not_execute_on_discovery(self):
        env = self.stub("tmux", "import sys\nassert sys.argv[1]=='list-panes'\nprint('$1\\t@2\\t%3\\tworkspace:0.0 editor')\n")
        env.pop("TMUX", None)
        outside = self.nu("gamepad tmux-items", env=env)
        self.assertIn("attach-session", outside[0]["command"])
        for target in ["$1", "@2", "%3"]:
            self.assertIn(target, outside[0]["command"])
        inside = self.nu("gamepad tmux-items", env=dict(env, TMUX="test"))
        self.assertIn("switch-client", inside[0]["command"])
        self.assertIn("new-window", inside[-1]["command"])

    @unittest.skipUnless(os.environ.get("GAMEPAD_TEST_REAL_TMUX"), "requires local Unix socket permission")
    def test_real_tmux_discovery(self):
        env = dict(self.env, TMUX_TMPDIR=str(self.base))
        env.pop("TMUX", None)
        started = subprocess.run(["tmux", "-f", "/dev/null", "new-session", "-d", "-s", "controller-test", "sleep 120"],
                                 env=env, text=True, capture_output=True)
        self.assertEqual(started.returncode, 0, started.stderr)
        try:
            subprocess.run(["tmux", "split-window", "-h", "-t", "controller-test", "sleep 120"], env=env, check=True)
            items = self.nu("gamepad tmux-items", env=env)
            self.assertEqual(len(items), 3)  # two panes and new session
            self.assertTrue(all("controller-test" in item["label"] for item in items[:2]))
        finally:
            subprocess.run(["tmux", "kill-server"], env=env, capture_output=True)


if __name__ == "__main__":
    unittest.main(verbosity=2)

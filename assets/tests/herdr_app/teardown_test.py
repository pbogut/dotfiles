"""Check interactive teardown scripts without a running App or core."""

import os
from pathlib import Path
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[3]
RUNNER = ROOT / "dot_config/herdr-app/mods/pbogut-tabs/teardown.sh"


class TeardownTest(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory(prefix="herdr-teardown-", dir="/tmp/opencode")
        self.addCleanup(self.tmp.cleanup)
        self.root = Path(self.tmp.name)
        self.project = self.root / "project's folder"
        self.worktree = self.project / "work tree"
        self.worktree.mkdir(parents=True)
        self.script = self.project / "teardown script's.sh"
        self.log = self.root / "runs"
        bindir = self.root / "bin"
        bindir.mkdir()
        hc = bindir / "hc"
        hc.write_text('#!/bin/sh\nprintf "%s\\n" "$*" >> "$LABEL_LOG"\n')
        hc.chmod(0o700)
        self.env = {**os.environ, "PATH": f"{bindir}:{os.environ['PATH']}",
                    "HC_TERMINAL_ID": "test", "LABEL_LOG": str(self.root / "labels"),
                    "HOOK_LOG": str(self.log), "HERDR_ENV": "1"}

    def run_hook(self, input="\n", folder=None):
        return subprocess.run(["bash", str(RUNNER), str(self.project), self.script.name, "attempt"],
                              cwd=folder or self.worktree, env=self.env, input=input,
                              text=True, capture_output=True, timeout=10)

    def test_interactive_hook_receives_context_and_runs_on_every_close(self):
        self.script.write_text(
            'read -r answer\n'
            'printf "%s\\n" "$HERDR_PROJECT_DIR" "$HERDR_WORKTREE_DIR" "$PWD" "$answer" "${HERDR_ENV-unset}" >> "$HOOK_LOG"\n')
        for _ in range(2):
            result = self.run_hook("continue\n")
            self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(self.log.read_text().splitlines(),
                         [str(self.project), str(self.worktree), str(self.worktree), "continue", "unset"] * 2)
        self.assertEqual((self.root / "labels").read_text().count("pbogut.teardown.state=success"), 2)

    def test_failure_and_missing_script_report_failure_and_allow_retry(self):
        self.script.write_text('echo "Cleanup failed" >&2\nexit 17\n')
        result = self.run_hook()
        self.assertEqual(result.returncode, 17)
        self.assertIn("Cleanup failed", result.stderr)
        self.assertIn("The project stays open", result.stdout)
        self.script.unlink()
        self.assertNotEqual(self.run_hook().returncode, 0)
        self.assertNotIn("pbogut.teardown.state=success", (self.root / "labels").read_text())
        self.script.write_text("exit 0\n")
        self.assertEqual(self.run_hook().returncode, 0)

    def test_cleanup_can_remove_the_worktree_and_still_report_success(self):
        self.script.write_text('rm -rf -- "$HERDR_WORKTREE_DIR"\n')
        result = self.run_hook()
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertFalse(self.worktree.exists())
        self.assertIn("pbogut.teardown.state=success", (self.root / "labels").read_text())

    def test_subdirectories_run_teardown_from_the_worktree_root(self):
        subprocess.run(["git", "init", "-q", str(self.worktree)], env=self.env, check=True)
        nested = self.worktree / "nested"
        nested.mkdir()
        self.script.write_text('printf "%s\\n" "$PWD" > "$HOOK_LOG"\n')
        self.assertEqual(self.run_hook(folder=nested).returncode, 0)
        self.assertEqual(self.log.read_text().splitlines(), [str(self.worktree)])


if __name__ == "__main__":
    unittest.main()

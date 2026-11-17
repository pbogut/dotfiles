"""Check setup persistence and locking without a running App or core."""

import hashlib
import os
from pathlib import Path
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[3]
RUNNER = ROOT / "dot_config/herdr-app/mods/pbogut-tabs/setup.sh"


class SetupTest(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory(prefix="herdr-setup-", dir="/tmp/opencode")
        self.addCleanup(self.tmp.cleanup)
        self.root = Path(self.tmp.name)
        self.project = self.root / "project's folder"
        self.worktree = self.project / "work tree"
        self.worktree.mkdir(parents=True)
        (self.worktree / ".git").write_text("gitdir: fixture")
        self.script = self.project / "setup script's.sh"
        self.log = self.root / "runs"
        bindir = self.root / "bin"
        bindir.mkdir()
        hc = bindir / "hc"
        hc.write_text('#!/bin/sh\nprintf "%s\\n" "$*" >> "$LABEL_LOG"\n')
        hc.chmod(0o700)
        self.env = {**os.environ, "PATH": f"{bindir}:{os.environ['PATH']}",
                    "HC_TERMINAL_ID": "test", "LABEL_LOG": str(self.root / "labels"),
                    "SETUP_LOG": str(self.log), "HERDR_ENV": "1"}
        self.script.write_text('printf "%s\\n" "$PWD" >> "$SETUP_LOG"\n')

    def argv(self, mode="run"):
        return ["bash", str(RUNNER), mode, str(self.root / "app"),
                str(self.project), self.script.name, "attempt"]

    def run_setup(self, mode="run", folder=None, input="\n"):
        return subprocess.run(self.argv(mode), cwd=folder or self.worktree, env=self.env,
                              input=input, text=True, capture_output=True, timeout=10)

    def test_interactive_script_receives_paths_and_only_success_is_cached(self):
        self.script.write_text(
            'read -r answer\n'
            'printf "%s\\n" "$HERDR_PROJECT_DIR" "$HERDR_WORKTREE_DIR" "$PWD" "$answer" "${HERDR_ENV-unset}" > "$SETUP_LOG"\n')
        digest = hashlib.sha256(self.script.read_bytes()).hexdigest()
        check = self.run_setup("check")
        self.assertEqual(check.returncode, 75)
        self.assertEqual(check.stdout.strip(), digest)
        result = self.run_setup(input="interactive answer\n")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(self.log.read_text().splitlines(),
                         [str(self.project), str(self.worktree), str(self.worktree), "interactive answer", "unset"])
        check = self.run_setup("check")
        self.assertEqual(check.returncode, 0)
        self.assertEqual(check.stdout.strip(), digest)
        self.assertIn(f"pbogut.setup.hash={digest}", (self.root / "labels").read_text())
        self.assertIn("pbogut.setup.state=success", (self.root / "labels").read_text())

    def test_script_contents_worktrees_and_recreated_worktrees_are_independent(self):
        original = self.script.read_text()
        for contents in [original, original, original + "# changed\n", original]:
            self.script.write_text(contents)
            self.assertEqual(self.run_setup().returncode, 0)
        sibling = self.project / "sibling"
        sibling.mkdir()
        self.assertEqual(self.run_setup(folder=sibling).returncode, 0)
        (self.worktree / ".git").rename(self.worktree / ".git-old")
        (self.worktree / ".git").write_text("new worktree")
        self.assertEqual(self.run_setup().returncode, 0)
        self.assertEqual(self.log.read_text().splitlines(),
                          [str(self.worktree), str(self.worktree), str(sibling), str(self.worktree)])

    def test_old_version_records_require_one_fresh_run(self):
        self.assertEqual(self.run_setup().returncode, 0)
        marker = next(path for path in (self.root / "app/state/project-setup").iterdir()
                      if path.suffix != ".lock")
        marker.rename(marker.with_suffix(".1"))
        self.assertEqual(self.run_setup("check").returncode, 75)
        self.assertEqual(self.run_setup().returncode, 0)
        self.assertEqual(self.run_setup().returncode, 0)
        self.assertEqual(len(self.log.read_text().splitlines()), 2)

    def test_failure_and_missing_scripts_remain_retryable(self):
        self.script.write_text('echo "Dependency failed" >&2\nexit 17\n')
        result = self.run_setup()
        self.assertEqual(result.returncode, 17)
        self.assertIn("Dependency failed", result.stderr)
        self.assertIn("Setup failed (exit 17)", result.stdout)
        self.assertEqual(self.run_setup("check").returncode, 75)
        self.script.unlink()
        self.assertNotEqual(self.run_setup().returncode, 0)
        self.assertEqual(self.run_setup("check").returncode, 1)
        self.script.write_text("exit 0\n")
        self.assertEqual(self.run_setup().returncode, 0)
        self.assertEqual(self.run_setup("check").returncode, 0)

    def test_opening_a_subdirectory_uses_the_worktree_root_and_same_marker(self):
        (self.worktree / ".git").unlink()
        subprocess.run(["git", "init", "-q", str(self.worktree)], env=self.env, check=True)
        nested = self.worktree / "nested"
        nested.mkdir()
        self.assertEqual(self.run_setup(folder=nested).returncode, 0)
        self.assertEqual(self.log.read_text().splitlines(), [str(self.worktree)])
        self.assertEqual(self.run_setup("check").returncode, 0)

    def test_concurrent_launches_run_the_hook_once(self):
        gate = self.root / "gate"
        os.mkfifo(gate)
        self.env["GATE"] = str(gate)
        self.script.write_text('echo run >> "$SETUP_LOG"\nread -r _ < "$GATE"\n')
        processes = [subprocess.Popen(self.argv(), cwd=self.worktree, env=self.env,
                                      stdin=subprocess.DEVNULL, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
                     for _ in range(2)]
        try:
            with gate.open("w") as stream:
                stream.write("continue\n")
            for process in processes:
                _, error = process.communicate(timeout=10)
                self.assertEqual(process.returncode, 0, error)
            self.assertEqual(self.log.read_text(), "run\n")
        finally:
            for process in processes:
                if process.poll() is None:
                    process.kill()
                    process.communicate()


if __name__ == "__main__":
    unittest.main()

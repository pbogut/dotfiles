import json
import os
from pathlib import Path
import subprocess
import tempfile
import textwrap
import unittest


ROOT = Path(__file__).resolve().parents[3]
SELECTOR = ROOT / "dot_scripts/executable_herdr-select-tab-or-new"
SESSION_CACHE = (
    ROOT
    / "dot_config/herdr/plugins/repo-metadata/executable_cache-opencode-session.sh"
)


class HerdrWorkflowTest(unittest.TestCase):
    def setUp(self):
        self.tempdir = tempfile.TemporaryDirectory()
        self.addCleanup(self.tempdir.cleanup)
        self.temp = Path(self.tempdir.name)
        self.log = self.temp / "herdr.jsonl"
        bindir = self.temp / "bin"
        bindir.mkdir()
        fake_herdr = bindir / "herdr"
        fake_herdr.write_text(
            textwrap.dedent(
                """\
                #!/usr/bin/env python3
                import json
                import os
                import sys

                args = sys.argv[1:]
                with open(os.environ["FAKE_HERDR_LOG"], "a", encoding="utf-8") as log:
                    log.write(json.dumps(args) + "\\n")

                if args[:2] == ["tab", "list"]:
                    print(os.environ["FAKE_HERDR_TABS"])
                elif args[:2] == ["workspace", "get"]:
                    print(json.dumps({"result": {"workspace": {"tokens": {}}}}))
                else:
                    print(json.dumps({"result": {}}))
                """
            )
        )
        fake_herdr.chmod(0o755)
        self.env = os.environ.copy()
        self.env.update(
            {
                "FAKE_HERDR_LOG": str(self.log),
                "FAKE_HERDR_TABS": json.dumps({"result": {"tabs": []}}),
                "HERDR_ACTIVE_WORKSPACE_ID": "w1",
                "HERDR_BIN_PATH": str(fake_herdr),
                "HERDR_SOCKET_PATH": str(self.temp / "herdr.sock"),
                "PATH": f"{bindir}:{os.environ['PATH']}",
            }
        )

    def run_script(self, script, *args, env=None):
        return subprocess.run(
            ["bash", str(script), *args],
            check=False,
            capture_output=True,
            text=True,
            env=env or self.env,
        )

    def calls(self):
        if not self.log.exists():
            return []
        return [json.loads(line) for line in self.log.read_text().splitlines()]

    def test_existing_role_focuses_without_replacing_other_tabs(self):
        self.env["FAKE_HERDR_TABS"] = json.dumps(
            {
                "result": {
                    "tabs": [
                        {"tab_id": "custom-tab", "label": "logs", "number": 1},
                        {"tab_id": "shell-tab", "label": "shell", "number": 2},
                    ]
                }
            }
        )

        result = self.run_script(SELECTOR, "shell")

        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(
            self.calls(),
            [
                ["tab", "list", "--workspace", "w1"],
                ["tab", "focus", "shell-tab"],
            ],
        )

    def test_numeric_alias_and_no_focus_keep_existing_tab(self):
        self.env["FAKE_HERDR_TABS"] = json.dumps(
            {
                "result": {
                    "tabs": [
                        {"tab_id": "shell-tab", "label": "shell", "number": 1},
                    ]
                }
            }
        )

        result = self.run_script(SELECTOR, "2", "--no-focus")

        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(
            self.calls(), [["tab", "list", "--workspace", "w1"]]
        )

    def test_session_cache_accepts_only_native_opencode_ids(self):
        valid_pane = {
            "pane_id": "p1",
            "workspace_id": "w1",
            "agent_session": {
                "agent": "opencode",
                "source": "herdr:opencode",
                "kind": "id",
                "value": "ses_exact_123",
            },
        }
        env = self.env.copy()
        env["HERDR_PLUGIN_EVENT_JSON"] = json.dumps({"data": {"pane": valid_pane}})

        result = self.run_script(SESSION_CACHE, env=env)

        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(
            self.calls(),
            [
                ["workspace", "get", "w1"],
                [
                    "workspace",
                    "report-metadata",
                    "w1",
                    "--source",
                    "plugin:pbogut.repo-metadata",
                    "--token",
                    "opencode_session=ses_exact_123",
                ],
            ],
        )

        for field, value in (
            ("agent", "other"),
            ("source", "screen"),
            ("kind", "name"),
        ):
            with self.subTest(field=field):
                self.log.unlink(missing_ok=True)
                pane = json.loads(json.dumps(valid_pane))
                pane["agent_session"][field] = value
                env["HERDR_PLUGIN_EVENT_JSON"] = json.dumps(
                    {"data": {"pane": pane}}
                )

                result = self.run_script(SESSION_CACHE, env=env)

                self.assertEqual(result.returncode, 0, result.stderr)
                self.assertEqual(self.calls(), [])


if __name__ == "__main__":
    unittest.main()

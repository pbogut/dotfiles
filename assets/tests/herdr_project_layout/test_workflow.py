import json
import os
from pathlib import Path
import socket
import subprocess
import tempfile
import textwrap
import threading
import time
import unittest


ROOT = Path(__file__).resolve().parents[3]
PROJECT_PLUGIN = ROOT / "dot_config/herdr/plugins/project-layout"
RUNTIME = PROJECT_PLUGIN / "lib/runtime.sh"
SELECTOR = PROJECT_PLUGIN / "executable_managed-tabs"
OPENCODE_LAUNCHER = ROOT / "dot_scripts/executable_opencode-launcher"
SESSION_CACHE = PROJECT_PLUGIN / "executable_cache-opencode-session.sh"


class FakeHerdrApi:
    def __init__(self, socket_path):
        self.socket_path = str(socket_path)
        self.requests = []
        self.server = socket.socket(socket.AF_UNIX)
        self.server.bind(self.socket_path)
        self.server.listen()
        self.stopping = threading.Event()
        self.thread = threading.Thread(target=self.serve, daemon=True)

    def __enter__(self):
        self.thread.start()
        return self

    def __exit__(self, *_):
        self.stopping.set()
        with socket.socket(socket.AF_UNIX) as client:
            client.connect(self.socket_path)
        self.thread.join(timeout=2)
        self.server.close()

    def serve(self):
        while not self.stopping.is_set():
            client, _ = self.server.accept()
            with client:
                input_bytes = b""
                while b"\n" not in input_bytes:
                    chunk = client.recv(65536)
                    if not chunk:
                        break
                    input_bytes += chunk
                if not input_bytes or self.stopping.is_set():
                    continue
                request = json.loads(input_bytes.split(b"\n", 1)[0])
                self.requests.append(request)
                response = {
                    "id": request["id"],
                    "result": {
                        "layout": {"tab_id": "new-tab", "root_pane_id": "new-pane"}
                    },
                }
                client.sendall((json.dumps(response) + "\n").encode())


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
                elif args[:2] == ["pane", "list"]:
                    print(os.environ["FAKE_HERDR_PANES"])
                elif args[:2] == ["pane", "process-info"]:
                    print(os.environ["FAKE_HERDR_PROCESS_INFO"])
                elif args[:2] == ["workspace", "get"]:
                    print(os.environ["FAKE_HERDR_WORKSPACE"])
                else:
                    print(json.dumps({"result": {}}))
                """
            )
        )
        fake_herdr.chmod(0o755)
        self.env = os.environ.copy()
        worktree = self.temp / "worktree"
        worktree.mkdir()
        self.env.update(
            {
                "FAKE_HERDR_LOG": str(self.log),
                "FAKE_HERDR_PANES": json.dumps({"result": {"panes": []}}),
                "FAKE_HERDR_PROCESS_INFO": json.dumps(
                    {"result": {"process_info": {"foreground_processes": []}}}
                ),
                "FAKE_HERDR_TABS": json.dumps({"result": {"tabs": []}}),
                "FAKE_HERDR_WORKSPACE": json.dumps(
                    {"result": {"workspace": {"tokens": {}}}}
                ),
                "HERDR_ACTIVE_WORKSPACE_ID": "w1",
                "HERDR_ACTIVE_PANE_CWD": str(worktree),
                "HERDR_BIN_PATH": str(fake_herdr),
                "HERDR_SOCKET_PATH": str(self.temp / "herdr.sock"),
                "PATH": f"{bindir}:{os.environ['PATH']}",
                "XDG_RUNTIME_DIR": str(self.temp / "runtime"),
            }
        )
        (self.temp / "runtime").mkdir()

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

    def test_missing_role_uses_layout_apply_with_direct_argv(self):
        api_path = self.temp / "layout.sock"
        self.env["HERDR_SOCKET_PATH"] = str(api_path)

        with FakeHerdrApi(api_path) as api:
            result = self.run_script(SELECTOR, "dev", "--no-focus")

        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(len(api.requests), 1)
        request = api.requests[0]
        self.assertEqual(request["method"], "layout.apply")
        self.assertEqual(
            request["params"],
            {
                "workspace_id": "w1",
                "tab_label": "dev",
                "focus": False,
                "root": {
                    "type": "pane",
                    "cwd": self.env["HERDR_ACTIVE_PANE_CWD"],
                    "command": ["zsh", "-ic", "start-dev"],
                },
            },
        )
        self.assertFalse(
            any(call[:2] in (["pane", "run"], ["tab", "close"]) for call in self.calls())
        )

    def test_stale_opencode_tab_is_replaced_with_exact_session_argv(self):
        api_path = self.temp / "layout.sock"
        self.env["HERDR_SOCKET_PATH"] = str(api_path)
        self.env["FAKE_HERDR_TABS"] = json.dumps(
            {
                "result": {
                    "tabs": [
                        {"tab_id": "old-tab", "label": "opencode", "number": 1}
                    ]
                }
            }
        )
        session_id = "ses exact;$value"
        self.env["FAKE_HERDR_PANES"] = json.dumps(
            {
                "result": {
                    "panes": [
                        {
                            "pane_id": "old-pane",
                            "tab_id": "old-tab",
                            "workspace_id": "w1",
                            "agent_session": {
                                "agent": "opencode",
                                "source": "herdr:opencode",
                                "kind": "id",
                                "value": session_id,
                            },
                        }
                    ]
                }
            }
        )

        with FakeHerdrApi(api_path) as api:
            result = self.run_script(SELECTOR, "opencode")

        self.assertEqual(result.returncode, 0, result.stderr)
        layout = next(request for request in api.requests if request["method"] == "layout.apply")
        self.assertEqual(layout["params"]["tab_id"], "old-tab")
        self.assertNotIn("workspace_id", layout["params"])
        self.assertEqual(
            layout["params"]["root"]["command"],
            ["opencode-launcher", "--session", session_id, "--port"],
        )
        self.assertFalse(
            any(call[:2] in (["pane", "run"], ["tab", "close"]) for call in self.calls())
        )


class OpenCodeLauncherTest(unittest.TestCase):
    def setUp(self):
        self.tempdir = tempfile.TemporaryDirectory()
        self.addCleanup(self.tempdir.cleanup)
        self.temp = Path(self.tempdir.name)
        self.home = self.temp / "home"
        self.config_dir = self.home / ".config/opencode"
        self.config_dir.mkdir(parents=True)
        self.profile_config = self.config_dir / "personal-opencode.jsonc"
        self.profile_config.write_text("{}\n")
        self.log = self.temp / "opencode.json"
        bindir = self.temp / "bin"
        bindir.mkdir()

        opencode = bindir / "opencode-real"
        opencode.write_text(
            textwrap.dedent(
                """\
                #!/usr/bin/env python3
                import json
                import os
                import sys

                with open(os.environ["FAKE_OPENCODE_LOG"], "w", encoding="utf-8") as log:
                    json.dump(
                        {
                            "argv": sys.argv[1:],
                            "config": os.environ.get("OPENCODE_CONFIG"),
                        },
                        log,
                    )
                """
            )
        )
        opencode.chmod(0o755)

        mise = bindir / "mise"
        mise.write_text(
            textwrap.dedent(
                """\
                #!/usr/bin/env python3
                import os
                import sys

                if sys.argv[1:] != ["which", "opencode"]:
                    raise SystemExit(2)
                print(os.environ["FAKE_OPENCODE_BIN"])
                """
            )
        )
        mise.chmod(0o755)

        self.env = os.environ.copy()
        self.env.update(
            {
                "FAKE_OPENCODE_BIN": str(opencode),
                "FAKE_OPENCODE_LOG": str(self.log),
                "HOME": str(self.home),
                "PATH": f"{bindir}:{os.environ['PATH']}",
            }
        )
        self.env.pop("HERDR_PANE_ID", None)

    def test_profile_is_process_local_and_arguments_stay_separate(self):
        result = subprocess.run(
            [
                "bash",
                str(OPENCODE_LAUNCHER),
                "--profile",
                "personal",
                "--session",
                "ses_exact_123",
            ],
            check=False,
            capture_output=True,
            text=True,
            env=self.env,
        )

        self.assertEqual(result.returncode, 0, result.stderr)
        launched = json.loads(self.log.read_text())
        self.assertEqual(launched["config"], str(self.profile_config))
        self.assertEqual(
            launched["argv"], ["--session", "ses_exact_123", "--port"]
        )
        self.assertFalse((self.config_dir / "opencode.jsonc").exists())


class TopologyLockTest(unittest.TestCase):
    def setUp(self):
        self.tempdir = tempfile.TemporaryDirectory()
        self.addCleanup(self.tempdir.cleanup)
        self.temp = Path(self.tempdir.name)
        runtime_dir = self.temp / "runtime"
        runtime_dir.mkdir()
        self.env = os.environ.copy()
        self.env.update(
            {
                "HERDR_SOCKET_PATH": str(self.temp / "herdr-a.sock"),
                "RUNTIME_FILE": str(RUNTIME),
                "XDG_RUNTIME_DIR": str(runtime_dir),
            }
        )

    def start_holder(self):
        ready = self.temp / "ready"
        env = self.env.copy()
        env["READY"] = str(ready)
        holder = subprocess.Popen(
            [
                "bash",
                "-c",
                'source "$RUNTIME_FILE"; '
                'herdr_acquire_topology_lock w1; : >"$READY"; sleep 0.6',
            ],
            env=env,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True,
        )
        self.addCleanup(lambda: holder.poll() is None and holder.kill())
        for _ in range(100):
            if ready.exists():
                return holder
            if holder.poll() is not None:
                _, stderr = holder.communicate()
                self.fail(f"lock holder exited early: {stderr}")
            time.sleep(0.01)
        self.fail("lock holder did not become ready")

    def test_same_socket_and_workspace_serialize(self):
        holder = self.start_holder()

        started = time.monotonic()
        contender = subprocess.run(
            [
                "bash",
                "-c",
                'source "$RUNTIME_FILE"; herdr_acquire_topology_lock w1',
            ],
            env=self.env,
            check=False,
            capture_output=True,
            text=True,
            timeout=2,
        )
        elapsed = time.monotonic() - started
        _, holder_stderr = holder.communicate(timeout=2)

        self.assertEqual(contender.returncode, 0, contender.stderr)
        self.assertEqual(holder.returncode, 0, holder_stderr)
        self.assertGreater(elapsed, 0.35)

    def test_different_socket_does_not_block(self):
        holder = self.start_holder()
        env = self.env.copy()
        env["HERDR_SOCKET_PATH"] = str(self.temp / "herdr-b.sock")

        started = time.monotonic()
        contender = subprocess.run(
            [
                "bash",
                "-c",
                'source "$RUNTIME_FILE"; herdr_acquire_topology_lock w1',
            ],
            env=env,
            check=False,
            capture_output=True,
            text=True,
            timeout=2,
        )
        elapsed = time.monotonic() - started
        _, holder_stderr = holder.communicate(timeout=2)

        self.assertEqual(contender.returncode, 0, contender.stderr)
        self.assertEqual(holder.returncode, 0, holder_stderr)
        self.assertLess(elapsed, 0.3)

    def test_inherited_lock_is_reentrant(self):
        result = subprocess.run(
            [
                "bash",
                "-c",
                'source "$RUNTIME_FILE"; herdr_acquire_topology_lock w1; '
                "bash -c 'source \"$RUNTIME_FILE\"; herdr_acquire_topology_lock w1'",
            ],
            env=self.env,
            check=False,
            capture_output=True,
            text=True,
            timeout=2,
        )

        self.assertEqual(result.returncode, 0, result.stderr)


if __name__ == "__main__":
    unittest.main()

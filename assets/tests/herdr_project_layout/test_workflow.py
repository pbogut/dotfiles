import hashlib
import json
import os
from pathlib import Path
import socket
import subprocess
import tempfile
import textwrap
import threading
import time
import tomllib
import unittest


ROOT = Path(__file__).resolve().parents[3]
PROJECT_PLUGIN = ROOT / "dot_config/herdr/plugins/project-layout"
RUNTIME = PROJECT_PLUGIN / "lib/runtime.sh"
SELECTOR = PROJECT_PLUGIN / "executable_managed-tabs"
OPENCODE_LAUNCHER = ROOT / "dot_scripts/executable_opencode-launcher"
PROJECT_LAUNCHER = ROOT / "dot_scripts/executable_herdr-project.tmpl"
SESSION_CACHE = PROJECT_PLUGIN / "executable_cache-opencode-session.sh"
STARTUP = PROJECT_PLUGIN / "executable_startup.sh"
MANIFEST = PROJECT_PLUGIN / "herdr-plugin.toml"
PLUGIN_LINK_HOOK = ROOT / "run_onchange_after_link-herdr-plugins.sh.tmpl"


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
        self.bindir = bindir
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
                elif args[:2] == ["api", "snapshot"]:
                    print(os.environ["FAKE_HERDR_SNAPSHOT"])
                elif args[:3] == ["plugin", "pane", "open"]:
                    print(os.environ["FAKE_HERDR_PLUGIN_PANE_OPEN"])
                else:
                    print(json.dumps({"result": {}}))
                """
            )
        )
        fake_herdr.chmod(0o755)
        fake_selector = bindir / "herdr-select-tab-or-new"
        fake_selector.write_text(
            "#!/usr/bin/env bash\n"
            "herdr test restore-editor \"${HERDR_ACTIVE_WORKSPACE_ID:-}\" "
            "\"${HERDR_ACTIVE_PANE_CWD:-}\" \"$@\"\n"
        )
        fake_selector.chmod(0o755)
        fake_vim = bindir / "herdr-vim"
        fake_vim.write_text("#!/usr/bin/env bash\nexit 0\n")
        fake_vim.chmod(0o755)
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
                "FAKE_HERDR_PLUGIN_PANE_OPEN": json.dumps(
                    {"result": {"type": "ok"}}
                ),
                "FAKE_HERDR_SNAPSHOT": json.dumps(
                    {
                        "result": {
                            "snapshot": {
                                "focused_workspace_id": "w1",
                                "panes": [
                                    {
                                        "cwd": str(worktree),
                                        "workspace_id": "w1",
                                    }
                                ],
                            }
                        }
                    }
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

    def test_managed_selector_adopts_the_initial_workspace_tab(self):
        self.env["FAKE_HERDR_TABS"] = json.dumps(
            {
                "result": {
                    "tabs": [
                        {"tab_id": "initial-tab", "label": "1", "number": 1},
                    ]
                }
            }
        )

        result = self.run_script(SELECTOR, "nvim")

        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(
            self.calls(),
            [
                ["tab", "list", "--workspace", "w1"],
                ["tab", "rename", "initial-tab", "nvim"],
                ["pane", "list", "--workspace", "w1"],
                ["tab", "focus", "initial-tab"],
            ],
        )
        self.assertNotIn("herdr tab rename", PROJECT_LAUNCHER.read_text())

    def test_session_cache_accepts_only_native_opencode_ids(self):
        valid_pane = {
            "pane_id": "p1",
            "workspace_id": "w1",
                "agent_session": {
                    "agent": "opencode",
                    "source": "herdr:opencode",
                    "kind": "id",
                    "value": "ses exact;$value",
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
                    "plugin:pbogut.project-layout",
                    "--token",
                    "opencode_session=ses exact;$value",
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

    def test_teardown_caches_session_and_closes_tabs_before_cleanup(self):
        layout, worktree = self.project_fixture()
        layout.write_text(
            "HERDR_TABS=(nvim opencode)\n"
            "herdr_teardown() {\n"
            "  printf '%s\\n' '\"teardown\"' >> \"$FAKE_HERDR_LOG\"\n"
            "}\n"
        )
        session_id = "ses exact;$value"
        self.env.update(
            {
                "HERDR_PANE_ID": "teardown-pane",
                "HERDR_TAB_ID": "teardown-tab",
                "FAKE_HERDR_TABS": json.dumps(
                    {
                        "result": {
                            "tabs": [
                                {"tab_id": "nvim-tab", "label": "nvim", "number": 1},
                                {
                                    "tab_id": "opencode-tab",
                                    "label": "opencode",
                                    "number": 2,
                                },
                                {
                                    "tab_id": "teardown-tab",
                                    "label": "teardown",
                                    "number": 3,
                                },
                            ]
                        }
                    }
                ),
                "FAKE_HERDR_PANES": json.dumps(
                    {
                        "result": {
                            "panes": [
                                {
                                    "pane_id": "opencode-pane",
                                    "tab_id": "opencode-tab",
                                    "workspace_id": "w1",
                                    "cwd": str(worktree),
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
                ),
            }
        )

        result = self.run_script(
            PROJECT_PLUGIN / "executable_project-layout", "teardown"
        )

        self.assertEqual(result.returncode, 0, result.stderr)
        calls = self.calls()
        cache = [
            "workspace",
            "report-metadata",
            "w1",
            "--source",
            "plugin:pbogut.project-layout",
            "--token",
            f"opencode_session={session_id}",
        ]
        rename = ["tab", "rename", "teardown-tab", "teardown"]
        closed_tabs = [
            index
            for index, call in enumerate(calls)
            if isinstance(call, list) and call[:2] == ["tab", "close"]
        ]
        self.assertLess(calls.index(rename), calls.index(cache))
        self.assertLess(calls.index(cache), min(closed_tabs))
        self.assertLess(max(closed_tabs), calls.index("teardown"))
        self.assertLess(
            calls.index("teardown"), calls.index(["workspace", "close", "w1"])
        )
        self.assertNotIn(["tab", "close", "teardown-tab"], calls)

    def test_failed_teardown_restores_editor_in_surviving_directory(self):
        layout, worktree = self.project_fixture()
        project = worktree.parent
        layout.write_text(
            "HERDR_TABS=(nvim)\n"
            "herdr_teardown() {\n"
            "  rm -rf -- \"$HERDR_WORKTREE_DIR\"\n"
            "  return 42\n"
            "}\n"
        )
        self.env.update(
            {
                "HERDR_PANE_ID": "teardown-pane",
                "HERDR_TAB_ID": "teardown-tab",
                "FAKE_HERDR_TABS": json.dumps(
                    {
                        "result": {
                            "tabs": [
                                {"tab_id": "nvim-tab", "label": "nvim", "number": 1},
                                {
                                    "tab_id": "teardown-tab",
                                    "label": "teardown",
                                    "number": 2,
                                },
                            ]
                        }
                    }
                ),
                "FAKE_HERDR_PANES": json.dumps({"result": {"panes": []}}),
            }
        )

        result = subprocess.run(
            [
                "bash",
                str(PROJECT_PLUGIN / "executable_project-layout"),
                "teardown",
            ],
            input="\x1b",
            check=False,
            capture_output=True,
            text=True,
            env=self.env,
        )

        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertFalse(worktree.exists())
        calls = self.calls()
        restore = [
            "test",
            "restore-editor",
            "w1",
            str(project),
            "nvim",
            "--ensure-running",
        ]
        self.assertIn(restore, calls)
        self.assertLess(calls.index(restore), calls.index(["tab", "close", "teardown-tab"]))
        self.assertNotIn(["workspace", "close", "w1"], calls)
        self.assertIn("Workspace kept open.", result.stdout)

    def test_unified_startup_runs_every_module_in_order(self):
        modules = self.temp / "modules"
        modules.mkdir()
        order_log = self.temp / "startup-order"
        for name in ("report-repo.sh", "cache-opencode-session.sh", "managed-tabs"):
            (modules / name).write_text(
                "#!/usr/bin/env bash\n"
                "printf '%s %s\\n' \"${0##*/}\" \"$*\" >> \"$FAKE_STARTUP_LOG\"\n"
                "[[ ${FAKE_STARTUP_FAILURE:-} != \"${0##*/}\" ]]\n"
            )
        env = self.env.copy()
        env.update(
            {
                "FAKE_STARTUP_LOG": str(order_log),
                "HERDR_PLUGIN_ROOT": str(modules),
            }
        )
        expected = [
            "report-repo.sh --all",
            "cache-opencode-session.sh --all",
            "managed-tabs --restore-all",
        ]

        result = self.run_script(STARTUP, env=env)

        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(order_log.read_text().splitlines(), expected)

        order_log.unlink()
        env["FAKE_STARTUP_FAILURE"] = "report-repo.sh"
        result = self.run_script(STARTUP, env=env)

        self.assertEqual(result.returncode, 1, result.stderr)
        self.assertEqual(order_log.read_text().splitlines(), expected)

    def test_project_manifest_owns_all_workflow_hooks(self):
        with MANIFEST.open("rb") as manifest_file:
            manifest = tomllib.load(manifest_file)

        self.assertEqual(manifest["id"], "pbogut.project-layout")
        self.assertEqual(manifest["startup"], [{"command": ["bash", "startup.sh"]}])
        self.assertEqual(
            [(event["on"], event["command"]) for event in manifest["events"]],
            [
                ("worktree.created", ["bash", "project-layout", "event"]),
                ("worktree.opened", ["bash", "project-layout", "event"]),
                ("pane.created", ["bash", "report-repo.sh"]),
                ("pane.agent_detected", ["bash", "report-repo.sh"]),
                ("pane.agent_detected", ["bash", "cache-opencode-session.sh"]),
                ("pane.moved", ["bash", "report-repo.sh"]),
                (
                    "pane.agent_status_changed",
                    ["bash", "cache-opencode-session.sh"],
                ),
            ],
        )
        for entry in manifest["actions"] + manifest["panes"]:
            self.assertEqual(entry["command"][:2], ["bash", "project-layout"])

    def test_obsolete_plugins_are_removed_by_the_migration(self):
        for name in ("managed-tabs", "repo-metadata"):
            self.assertFalse((ROOT / "dot_config/herdr/plugins" / name).exists())

        remove_targets = (ROOT / ".chezmoiremove").read_text().splitlines()
        self.assertIn(".config/herdr/plugins/managed-tabs", remove_targets)
        self.assertIn(".config/herdr/plugins/repo-metadata", remove_targets)
        hook = PLUGIN_LINK_HOOK.read_text()
        self.assertIn("herdr plugin unlink pbogut.managed-tabs", hook)
        self.assertIn("herdr plugin unlink pbogut.repo-metadata", hook)
        self.assertIn('plugins/project-layout" --enabled', hook)

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

    def project_fixture(self):
        project = self.temp / "project"
        bare = project / ".bare"
        worktree = project / "main"
        project.mkdir()
        subprocess.run(
            ["git", "init", "--bare", str(bare)],
            check=True,
            capture_output=True,
            text=True,
        )
        subprocess.run(
            ["git", f"--git-dir={bare}", "worktree", "add", "--orphan", str(worktree)],
            check=True,
            capture_output=True,
            text=True,
        )
        layout = project / "herdr-project.sh"
        layout.write_text(
            'HERDR_TABS=(nvim)\nherdr_task "build assets" -- true\n'
        )
        config_dir = self.temp / "plugin-config"
        config_dir.mkdir()
        (config_dir / "trusted-projects.json").write_text(
            json.dumps([str(project.resolve())])
        )
        fzf = self.bindir / "fzf"
        fzf.write_text("#!/usr/bin/env bash\nIFS= read -r line\nprintf '%s\\n' \"$line\"\n")
        fzf.chmod(0o755)
        self.env.update(
            {
                "COLUMNS": "80",
                "FAKE_HERDR_SNAPSHOT": json.dumps(
                    {
                        "result": {
                            "snapshot": {
                                "focused_workspace_id": "w1",
                                "panes": [
                                    {
                                        "cwd": str(worktree),
                                        "workspace_id": "w1",
                                    }
                                ],
                            }
                        }
                    }
                ),
                "HERDR_LAYOUT_WORKSPACE_ID": "w1",
                "HERDR_LAYOUT_WORKTREE": str(worktree),
                "HERDR_PLUGIN_CONFIG_DIR": str(config_dir),
                "SHELL": "/bin/bash",
            }
        )
        return layout, worktree

    def test_setup_pane_open_accepts_a_generic_success_response(self):
        layout, _ = self.project_fixture()
        layout.write_text(
            "HERDR_TABS=(nvim)\n"
            "herdr_setup() { :; }\n"
        )

        result = self.run_script(
            PROJECT_PLUGIN / "executable_project-layout", "apply"
        )

        self.assertEqual(result.returncode, 0, result.stderr)
        calls = self.calls()
        pane_open = next(
            call for call in calls if call[:3] == ["plugin", "pane", "open"]
        )
        self.assertNotIn("--cwd", pane_open)
        self.assertIn(f"HERDR_LAYOUT_WORKTREE={layout.parent / 'main'}", pane_open)
        self.assertFalse(any(call[:2] == ["tab", "rename"] for call in calls))
        self.assertFalse(
            any(
                call[:3]
                == ["notification", "show", "Project setup tab was not named"]
                for call in calls
            )
        )

    def test_setup_pane_names_its_own_tab(self):
        layout, _ = self.project_fixture()
        layout.write_text(
            "HERDR_TABS=(nvim)\n"
            "herdr_setup() { :; }\n"
        )
        self.env.update(
            {
                "HERDR_PANE_ID": "setup-pane",
                "HERDR_PLUGIN_ENTRYPOINT_ID": "setup",
                "HERDR_TAB_ID": "setup-tab",
            }
        )

        result = subprocess.run(
            [
                "bash",
                str(PROJECT_PLUGIN / "executable_project-layout"),
                "setup",
            ],
            input="\n",
            check=False,
            capture_output=True,
            text=True,
            env=self.env,
        )

        self.assertEqual(result.returncode, 0, result.stderr)
        calls = self.calls()
        self.assertIn(["tab", "rename", "setup-tab", "setup"], calls)
        self.assertNotIn(
            ["notification", "show", "Project setup tab was not named"], calls
        )

    def test_new_project_task_uses_layout_apply(self):
        _, worktree = self.project_fixture()
        api_path = self.temp / "tasks.sock"
        self.env["HERDR_SOCKET_PATH"] = str(api_path)

        with FakeHerdrApi(api_path) as api:
            result = self.run_script(PROJECT_PLUGIN / "executable_project-layout", "task-picker")

        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(len(api.requests), 1)
        request = api.requests[0]
        self.assertEqual(request["method"], "layout.apply")
        self.assertEqual(request["params"]["workspace_id"], "w1")
        self.assertNotIn("tab_id", request["params"])
        self.assertEqual(request["params"]["tab_label"], "build assets")
        self.assertEqual(request["params"]["root"]["cwd"], str(worktree))
        self.assertEqual(
            request["params"]["root"]["command"],
            [
                str(PROJECT_PLUGIN / "project-layout"),
                "run-task",
                request["params"]["root"]["command"][2],
            ],
        )
        self.assertRegex(request["params"]["root"]["command"][2], r"^[0-9a-f]{64}$")
        self.assertFalse(
            any(call[:2] in (["pane", "run"], ["tab", "create"]) for call in self.calls())
        )

    def test_completed_project_task_rerun_replaces_its_tab(self):
        layout, _ = self.project_fixture()
        task_key = hashlib.sha256(
            f"{layout}\0build assets\0".encode()
        ).hexdigest()
        self.env["FAKE_HERDR_TABS"] = json.dumps(
            {
                "result": {
                    "tabs": [
                        {
                            "tab_id": "finished-tab",
                            "label": "build assets ✓",
                            "number": 1,
                        }
                    ]
                }
            }
        )
        self.env["FAKE_HERDR_PANES"] = json.dumps(
            {
                "result": {
                    "panes": [
                        {
                            "pane_id": "finished-pane",
                            "tab_id": "finished-tab",
                            "tokens": {
                                "layout_task": task_key,
                                "layout_task_state": "finished",
                            },
                        }
                    ]
                }
            }
        )
        self.env["FAKE_HERDR_PROCESS_INFO"] = json.dumps(
            {
                "result": {
                    "process_info": {
                        "shell_pid": 100,
                        "foreground_process_group_id": 100,
                        "foreground_processes": [
                            {"pid": 100, "name": "bash", "argv": ["bash"]}
                        ],
                    }
                }
            }
        )
        api_path = self.temp / "tasks.sock"
        self.env["HERDR_SOCKET_PATH"] = str(api_path)

        with FakeHerdrApi(api_path) as api:
            result = subprocess.run(
                [
                    "bash",
                    str(PROJECT_PLUGIN / "executable_project-layout"),
                    "task-picker",
                ],
                input="\n",
                check=False,
                capture_output=True,
                text=True,
                env=self.env,
            )

        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(len(api.requests), 1)
        request = api.requests[0]
        self.assertEqual(request["method"], "layout.apply")
        self.assertEqual(request["params"]["tab_id"], "finished-tab")
        self.assertNotIn("workspace_id", request["params"])
        self.assertEqual(request["params"]["root"]["command"][2], task_key)
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

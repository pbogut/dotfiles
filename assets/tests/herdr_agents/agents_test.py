import importlib.util
import json
import queue
import socket
import subprocess
import sys
import threading
import unittest
from pathlib import Path
from unittest import mock


HELPER = (
    Path(__file__).resolve().parents[3]
    / "dot_config/DankMaterialShell/plugins/HerdrAgents/executable_herdr-agents.py"
)
spec = importlib.util.spec_from_file_location("herdr_agents", HELPER)
helper = importlib.util.module_from_spec(spec)
spec.loader.exec_module(helper)


def terminal(address="t1", report_state="working", **fields):
    return {
        "address": address,
        "state": "live",
        "status": {"app": "opencode", "state": report_state, "title": "Fix widget"},
        "cwd": "/projects/widget",
        "labels": {"where": "widget / oc-1"},
        **fields,
    }


class RenderTests(unittest.TestCase):
    def test_merges_sources_and_keeps_focus_targets_distinct(self):
        legacy = {
            "agents": [
                {
                    "pane_id": "w1:p1",
                    "workspace_id": "w1",
                    "tab_id": "w1:t1",
                    "agent": "claude",
                    "agent_status": "blocked",
                    "terminal_title_stripped": "Review widget",
                }
            ],
            "workspaces": [{"workspace_id": "w1", "label": "Legacy project"}],
            "tabs": [{"tab_id": "w1:t1", "label": "Review"}],
        }
        payload = helper.render(legacy, [terminal()])
        self.assertEqual(payload["count"], 2)
        self.assertEqual(payload["dominant_status"], "blocked")
        self.assertEqual(payload["counts"]["blocked"], 1)
        self.assertEqual(payload["counts"]["working"], 1)
        old, new = [group["agents"][0] for group in payload["groups"]]
        self.assertEqual((old["source"], old["pane_id"]), ("herdr", "w1:p1"))
        self.assertEqual(old["workspace"], "Legacy project")
        self.assertEqual((new["source"], new["terminal_id"]), ("herdr-app", "t1"))
        self.assertEqual(new["name"], "Fix widget")
        self.assertEqual((new["project"], new["tab"]), ("widget", "oc-1"))

    def test_filters_shells_and_finished_agents(self):
        payload = helper.render(
            None,
            [
                terminal("shell", status=None),
                terminal("finished", state="finished"),
                terminal("idle", "idle"),
            ],
        )
        self.assertEqual(payload["count"], 1)
        self.assertEqual(payload["counts"]["idle"], 1)
        self.assertEqual(payload["groups"][0]["agents"][0]["terminal_id"], "idle")

    def test_subagents_inherit_location_but_keep_their_own_address(self):
        agents = helper.core_agents(
            [
                terminal("remote/t1"),
                terminal("remote/t2", labels={}, parent="remote/t1"),
            ]
        )
        self.assertEqual(agents[1]["terminal_id"], "remote/t2")
        self.assertEqual((agents[1]["workspace"], agents[1]["tab"]), ("widget", "oc-1"))

    def test_title_and_location_fallbacks_and_unknown_status(self):
        agent = helper.core_agents(
            [
                terminal(
                    status={"app": "opencode", "state": "custom"},
                    title="Terminal title",
                    labels={},
                )
            ]
        )[0]
        self.assertEqual(agent["status"], "unknown")
        self.assertEqual(agent["name"], "Terminal title")
        self.assertEqual(agent["project"], "widget")
        self.assertEqual(agent["tab"], "")

    def test_no_agents_matches_the_daemon_empty_payload(self):
        self.assertEqual(helper.render(None), helper.empty_payload())
        self.assertEqual(helper.render({}, [terminal(status=None)]), helper.empty_payload())

    def test_app_snapshot_supplies_done_and_focus_then_disconnect_falls_back(self):
        terminals = [terminal("t1", "idle"), terminal("t2", "idle")]
        app = {
            "t1": {"status": "done", "focused": False},
            "t2": {"status": "idle", "focused": True},
        }
        payload = helper.render(None, terminals, app)
        self.assertTrue(payload["app_connected"])
        self.assertEqual(payload["counts"]["done"], 1)
        self.assertEqual(payload["groups"][1]["agents"][0]["terminal_id"], "t2")
        self.assertTrue(payload["groups"][1]["agents"][0]["focused"])
        payload = helper.render(None, terminals, None)
        self.assertFalse(payload["app_connected"])
        self.assertEqual(payload["counts"]["idle"], 2)
        self.assertFalse(any(agent["focused"] for agent in payload["groups"][0]["agents"]))

    def test_app_focus_controls_sorting_and_cannot_restore_a_finished_terminal(self):
        app = {
            "t1": {"status": "idle", "focused": False},
            "t2": {"status": "idle", "focused": True},
            "gone": {"status": "done", "focused": False},
        }
        payload = helper.render(None, [terminal("t1", "idle"), terminal("t2", "idle")], app)
        self.assertEqual(payload["count"], 2)
        self.assertEqual(
            [agent["terminal_id"] for agent in payload["groups"][0]["agents"]],
            ["t2", "t1"],
        )


class StreamTests(unittest.TestCase):
    def event(self, sequence, kind, data=None, address="t1"):
        return {
            "method": "event",
            "params": {
                "seq": sequence,
                "terminal": address,
                "type": kind,
                "data": data or {},
            },
        }

    def payloads(self, *messages):
        return [
            helper.render(None, terminals)
            for terminals in helper.core_updates(json.dumps(message) for message in messages)
        ]

    def test_snapshot_and_status_clear_follow_actual_core_event_format(self):
        payloads = self.payloads(
            {"seq": 1, "terminals": [terminal()]},
            self.event(2, "status", {"status": {"app": "opencode", "state": "idle"}, "reported": True}),
            # The turn event's state is the reported word, NOT live/finished.
            self.event(3, "turn", {"turn": 1, "state": "idle"}),
            self.event(4, "labels", {"labels": {"where": "Renamed / tab"}}),
            self.event(5, "status", {"status": None, "records": {}, "reported": True}),
        )
        self.assertEqual([item["count"] for item in payloads], [1, 1, 1, 0])
        self.assertEqual(payloads[1]["counts"]["idle"], 1)
        self.assertEqual(payloads[2]["groups"][0]["agents"][0]["project"], "Renamed")
        self.assertEqual(payloads[0]["counts"]["working"], 1, "queued snapshots stay immutable")

    def test_creation_loss_restart_finish_and_removal(self):
        payloads = self.payloads(
            {"seq": 0, "terminals": []},
            self.event(1, "created", terminal()),
            self.event(2, "lost", {"reason": "holder_lost"}),
            self.event(3, "restarted", terminal(status=None)),
            self.event(4, "status", {"status": {"state": "blocked", "app": "opencode"}}),
            self.event(5, "finished", {"reason": "exited"}),
            self.event(6, "removed"),
        )
        self.assertEqual([item["count"] for item in payloads], [0, 1, 0, 0, 1, 0, 0])
        self.assertEqual(payloads[4]["counts"]["blocked"], 1)

    def test_missed_snapshot_replaces_old_agents_and_discards_older_events(self):
        payloads = self.payloads(
            {"seq": 1, "terminals": [terminal()]},
            {"method": "missed", "params": {"seq": 10, "terminals": [terminal("remote/t2")]}},
            self.event(9, "created", terminal()),
            {"method": "heartbeat", "params": {"seq": 11}},
            self.event(12, "title", {"title": "New title"}, "remote/t2"),
        )
        self.assertEqual(len(payloads), 3)
        self.assertEqual(payloads[-1]["count"], 1)
        self.assertEqual(payloads[-1]["groups"][0]["agents"][0]["terminal_id"], "remote/t2")


class WatcherTests(unittest.TestCase):
    def test_bad_stream_reconnects_and_shutdown_reaps_the_child(self):
        updates, stop = queue.Queue(), threading.Event()
        processes = []
        popen = subprocess.Popen
        snapshot = json.dumps({"seq": 1, "terminals": [terminal()]})

        def spawn(command, **kwargs):
            self.assertEqual(command, ["hc", "events", "--json"])
            program = (
                "print('invalid json', flush=True)"
                if not processes
                else f"import sys; print({snapshot!r}, flush=True); sys.stdin.read()"
            )
            process = popen([sys.executable, "-u", "-c", program], stdin=subprocess.PIPE, **kwargs)
            processes.append(process)
            return process

        with mock.patch.object(helper.subprocess, "Popen", side_effect=spawn), mock.patch.object(
            helper, "RETRY_INTERVAL", 0.01
        ):
            watcher = threading.Thread(target=helper.watch_core, args=(updates, stop), daemon=True)
            watcher.start()
            try:
                self.assertEqual(updates.get(timeout=3), ("herdr-app", []))
                source, terminals = updates.get(timeout=3)
                self.assertEqual(source, "herdr-app")
                self.assertEqual(helper.render(None, terminals)["count"], 1)
            finally:
                stop.set()
                watcher.join(timeout=3)
                for process in processes:
                    if process.poll() is None:
                        process.kill()
                        process.wait()
                    process.stdin.close()
            self.assertFalse(watcher.is_alive())
            self.assertEqual(len(processes), 2)
            self.assertTrue(all(process.returncode is not None for process in processes))

    def test_missing_hc_clears_only_the_app_source(self):
        updates, stop = queue.Queue(), threading.Event()

        def missing(*args, **kwargs):
            stop.set()
            raise FileNotFoundError("hc")

        with mock.patch.object(helper.subprocess, "Popen", side_effect=missing):
            helper.watch_core(updates, stop)
        self.assertEqual(updates.get_nowait(), ("herdr-app", []))
        self.assertTrue(updates.empty())


class AppPushTests(unittest.TestCase):
    def setUp(self):
        self.listener = socket.socket()
        self.listener.bind(("127.0.0.1", 0))
        self.listener.listen()
        self.updates, self.stop = queue.Queue(), threading.Event()
        self.clients = []
        self.worker = threading.Thread(
            target=helper.serve_app, args=(self.listener, self.updates, self.stop), daemon=True
        )
        self.worker.start()

    def tearDown(self):
        self.stop.set()
        for client in self.clients:
            client.close()
        self.worker.join(timeout=2)
        self.listener.close()
        self.assertFalse(self.worker.is_alive())

    def connect(self):
        client = socket.create_connection(self.listener.getsockname(), timeout=2)
        self.clients.append(client)
        self.assertEqual(self.updates.get(timeout=2), ("app-status", None))
        return client

    def snapshot(self, agents):
        return json.dumps({"version": 1, "agents": agents}).encode() + b"\n"

    def test_fragmented_snapshots_replace_state_and_eof_clears_it(self):
        client = self.connect()
        agent = {"address": "t1", "status": "done", "focused": False}
        frame = self.snapshot([agent])
        client.sendall(frame[:10])
        with self.assertRaises(queue.Empty):
            self.updates.get(timeout=0.05)
        client.sendall(frame[10:])
        self.assertEqual(self.updates.get(timeout=2), (
            "app-status", {"t1": {"status": "done", "focused": False}},
        ))
        client.sendall(self.snapshot([]))
        self.assertEqual(self.updates.get(timeout=2), ("app-status", {}))
        client.close()
        self.assertEqual(self.updates.get(timeout=2), ("app-status", None))

    def test_new_connection_replaces_the_old_one_and_requires_a_fresh_snapshot(self):
        first = self.connect()
        first.sendall(self.snapshot([{"address": "t1", "status": "idle", "focused": True}]))
        self.updates.get(timeout=2)
        second = self.connect()
        self.assertEqual(first.recv(1), b"")
        second.sendall(self.snapshot([{"address": "t2", "status": "done", "focused": False}]))
        self.assertEqual(self.updates.get(timeout=2)[1], {
            "t2": {"status": "done", "focused": False},
        })

    def test_invalid_or_oversized_messages_close_the_connection(self):
        for frame in [b"invalid\n", b"x" * 130]:
            with self.subTest(frame=frame), mock.patch.object(helper, "APP_MESSAGE_LIMIT", 128):
                client = self.connect()
                client.sendall(frame)
                self.assertEqual(self.updates.get(timeout=2), ("app-status", None))
                self.assertEqual(client.recv(1), b"")

    def test_schema_rejects_unknown_versions_and_malformed_agents(self):
        for message in [
            [], {"version": 2, "agents": []}, {"version": 1},
            {"version": 1, "agents": [None]},
            {"version": 1, "agents": [{"address": "t1", "status": "idle", "focused": "false"}]},
            {"version": 1, "agents": [{"address": "", "status": "idle", "focused": False}]},
        ]:
            with self.subTest(message=message), self.assertRaises(ValueError):
                helper.parse_app_status(json.dumps(message))


if __name__ == "__main__":
    unittest.main()

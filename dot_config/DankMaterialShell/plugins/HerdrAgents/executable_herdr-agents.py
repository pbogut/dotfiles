#!/usr/bin/env python3

import json
import os
import queue
import select
import signal
import socket
import subprocess
import sys
import threading
import time
from pathlib import Path


STATUSES = ("blocked", "working", "done", "idle", "unknown")
EVENTS = (
    "workspace.renamed",
    "workspace.closed",
    "tab.closed",
    "tab.renamed",
    "pane.closed",
    "pane.moved",
    "pane.exited",
    "pane.agent_detected",
)
RETRY_INTERVAL = 2
APP_PORT = 47653
APP_MESSAGE_LIMIT = 1024 * 1024


def herdr_socket_path():
    config_path = os.environ.get("HERDR_CONFIG_PATH")
    if config_path:
        return Path(config_path).expanduser().parent / "herdr.sock"

    config_home = Path(os.environ.get("XDG_CONFIG_HOME", Path.home() / ".config"))
    return config_home / "herdr" / "herdr.sock"


def open_socket():
    client = socket.socket(socket.AF_UNIX)
    client.settimeout(2)
    client.connect(str(herdr_socket_path()))
    return client


def send_request(stream, request):
    stream.write((json.dumps(request) + "\n").encode())
    stream.flush()
    response = json.loads(stream.readline())
    if "error" in response:
        raise RuntimeError(response["error"])
    return response["result"]


def snapshot():
    with open_socket() as client, client.makefile("rwb", buffering=0) as stream:
        result = send_request(
            stream,
            {"id": "dms:snapshot", "method": "session.snapshot", "params": {}},
        )
    return result["snapshot"]


def subscribe(data):
    subscriptions = [{"type": event} for event in EVENTS]
    subscriptions.extend(
        {
            "type": "pane.agent_status_changed",
            "pane_id": agent["pane_id"],
        }
        for agent in data.get("agents", [])
    )

    client = open_socket()
    stream = client.makefile("rwb", buffering=0)
    try:
        result = send_request(
            stream,
            {
                "id": "dms:subscribe",
                "method": "events.subscribe",
                "params": {"subscriptions": subscriptions},
            },
        )
        if result.get("type") != "subscription_started":
            raise RuntimeError("Herdr did not start the event subscription")
        client.settimeout(None)
        return client, stream
    except Exception:
        stream.close()
        client.close()
        raise


def drain_events(client, stream, max_duration=0.5):
    deadline = time.monotonic() + max_duration
    while time.monotonic() < deadline:
        readable, _, _ = select.select([client], [], [], 0.05)
        if not readable:
            return
        if not stream.readline():
            raise ConnectionError("Herdr event subscription closed")


def empty_payload():
    return {
        "count": 0,
        "dominant_status": "empty",
        "counts": {status: 0 for status in STATUSES},
        "groups": [],
        "app_connected": False,
    }


def core_agents(terminals, app_status=None):
    app_status = app_status or {}
    by_address = {item["address"]: item for item in terminals}
    agents = []
    for terminal in terminals:
        report = terminal.get("status")
        if terminal.get("state") != "live" or not report:
            continue

        labels = terminal.get("labels", {})
        parent = by_address.get(terminal.get("parent"), {})
        where = labels.get("where") or parent.get("labels", {}).get("where", "")
        workspace, separator, tab = where.rpartition(" / ")
        if not separator:
            workspace, tab = where, ""
        cwd = terminal.get("cwd", "")
        app = app_status.get(terminal["address"], {})
        status = app.get("status", report.get("state", "unknown"))
        agents.append(
            {
                "source": "herdr-app",
                "terminal_id": terminal["address"],
                "status": status if status in STATUSES else "unknown",
                "name": report.get("title")
                or terminal.get("title")
                or terminal.get("name")
                or report.get("app")
                or "Agent",
                "agent": report.get("app") or "agent",
                "workspace": workspace,
                "tab": tab,
                "project": workspace or Path(cwd).name,
                "feature": "",
                "cwd": cwd,
                "focused": app.get("focused", False),
            }
        )
    return agents


def render(data, terminals=(), app_status=None):
    data = data or {}

    workspaces = {
        item["workspace_id"]: item for item in data.get("workspaces", [])
    }
    tabs = {item["tab_id"]: item for item in data.get("tabs", [])}
    grouped = {status: [] for status in STATUSES}

    for agent in data.get("agents", []):
        status = agent.get("agent_status", "unknown")
        if status not in grouped:
            status = "unknown"

        workspace = workspaces.get(agent.get("workspace_id"), {})
        tab = tabs.get(agent.get("tab_id"), {})
        tokens = agent.get("tokens") or workspace.get("tokens") or {}
        grouped[status].append(
            {
                "source": "herdr",
                "pane_id": agent.get("pane_id", ""),
                "workspace_id": agent.get("workspace_id", ""),
                "tab_id": agent.get("tab_id", ""),
                "status": status,
                "name": agent.get("terminal_title_stripped")
                or agent.get("agent", "Agent"),
                "agent": agent.get("agent", "agent"),
                "workspace": workspace.get("label", "Unknown workspace"),
                "tab": tab.get("label", "Unknown tab"),
                "project": tokens.get("project", ""),
                "feature": tokens.get("feature", ""),
                "cwd": agent.get("cwd", ""),
                "focused": bool(agent.get("focused")),
            }
        )

    for agent in core_agents(terminals, app_status):
        grouped[agent["status"]].append(agent)

    groups = []
    for status in STATUSES:
        agents = grouped[status]
        if not agents:
            continue
        agents.sort(
            key=lambda agent: (
                not agent["focused"],
                agent["project"].lower(),
                agent["name"].lower(),
            )
        )
        groups.append({"status": status, "count": len(agents), "agents": agents})

    return {
        "count": sum(len(agents) for agents in grouped.values()),
        "dominant_status": next(
            (status for status in STATUSES if grouped[status]), "empty"
        ),
        "counts": {status: len(grouped[status]) for status in STATUSES},
        "groups": groups,
        "app_connected": app_status is not None,
    }


def agent_ids(data):
    return {agent["pane_id"] for agent in data.get("agents", [])}


def emit(data, previous, terminals=(), app_status=None):
    output = json.dumps(render(data, terminals, app_status), ensure_ascii=False)
    if output != previous:
        print(output, flush=True)
    return output


def watch_herdr(updates, stop):
    while not stop.is_set():
        client = None
        stream = None
        try:
            discovered = snapshot()
            client, stream = subscribe(discovered)
            subscribed_agents = agent_ids(discovered)

            # Generic subscriptions replay existing events before live updates.
            drain_events(client, stream)
            current = snapshot()
            updates.put(("herdr", current))
            if subscribed_agents != agent_ids(current):
                continue

            while not stop.is_set():
                if not stream.readline():
                    raise ConnectionError("Herdr event subscription closed")
                drain_events(client, stream)
                current = snapshot()
                updates.put(("herdr", current))
                if subscribed_agents != agent_ids(current):
                    break
        except (OSError, ValueError, KeyError, RuntimeError):
            updates.put(("herdr", None))
            stop.wait(RETRY_INTERVAL)
        finally:
            if stream is not None:
                stream.close()
            if client is not None:
                client.close()


def core_updates(stream):
    terminals = {}
    sequence = -1
    for line in stream:
        message = json.loads(line)
        if "error" in message:
            raise RuntimeError(message["error"])
        data = message.get("params", message)
        if "terminals" in data:
            terminals = {
                item["address"]: item
                for item in data["terminals"]
                if item.get("state") == "live"
            }
            sequence = data["seq"]
        elif message.get("method") == "event":
            if data["seq"] <= sequence:
                continue
            sequence = data["seq"]
            address = data.get("terminal")
            kind = data["type"]
            if kind in ("finished", "lost", "removed"):
                terminals.pop(address, None)
            elif kind in ("created", "restarted"):
                terminals[address] = data["data"]
            elif address in terminals and kind in ("status", "title", "labels"):
                terminals[address] = {**terminals[address], **data["data"]}
            else:
                continue
        else:
            continue
        yield list(terminals.values())


def core_lines(stream, stop):
    pending = b""
    while not stop.is_set():
        if not select.select([stream], [], [], 0.2)[0]:
            continue
        chunk = os.read(stream.fileno(), 65536)
        if not chunk:
            return
        pending += chunk
        while b"\n" in pending:
            line, pending = pending.split(b"\n", 1)
            yield line


def watch_core(updates, stop):
    while not stop.is_set():
        process = None
        try:
            process = subprocess.Popen(
                ["hc", "events", "--json"],
                stdout=subprocess.PIPE,
                stderr=subprocess.DEVNULL,
            )
            for terminals in core_updates(core_lines(process.stdout, stop)):
                updates.put(("herdr-app", terminals))
        except (OSError, ValueError, KeyError, RuntimeError):
            pass
        finally:
            if process is not None:
                process.terminate()
                try:
                    process.wait(timeout=2)
                except subprocess.TimeoutExpired:
                    process.kill()
                    process.wait()
                process.stdout.close()
        updates.put(("herdr-app", []))
        stop.wait(RETRY_INTERVAL)


def parse_app_status(line):
    message = json.loads(line)
    if not isinstance(message, dict) or message.get("version") != 1:
        raise ValueError("Unsupported app status message")
    agents = message.get("agents")
    if not isinstance(agents, list):
        raise ValueError("Expected an agent snapshot")
    result = {}
    for agent in agents:
        if (
            not isinstance(agent, dict)
            or not isinstance(agent.get("address"), str)
            or not agent["address"]
            or agent.get("status") not in STATUSES
            or not isinstance(agent.get("focused"), bool)
            or agent["address"] in result
        ):
            raise ValueError("Invalid app agent")
        result[agent["address"]] = {
            "status": agent["status"],
            "focused": agent["focused"],
        }
    return result


def serve_app(listener, updates, stop):
    client = None
    pending = b""
    try:
        while not stop.is_set():
            readable, _, _ = select.select(
                [listener] + ([client] if client else []), [], [], 0.2
            )
            if listener in readable:
                incoming, _ = listener.accept()
                incoming.setblocking(False)
                if client:
                    client.close()
                client, pending = incoming, b""
                updates.put(("app-status", None))
            if client not in readable:
                continue
            try:
                chunk = client.recv(65536)
                if not chunk:
                    raise ConnectionError("App status connection closed")
                pending += chunk
                if len(pending) > APP_MESSAGE_LIMIT:
                    raise ValueError("App status message too large")
                while b"\n" in pending:
                    line, pending = pending.split(b"\n", 1)
                    updates.put(("app-status", parse_app_status(line)))
            except (OSError, ValueError):
                client.close()
                client, pending = None, b""
                updates.put(("app-status", None))
    finally:
        if client:
            client.close()
        updates.put(("app-status", None))


def watch_app(updates, stop):
    port = int(os.environ.get("HERDR_AGENTS_PORT", APP_PORT))
    while not stop.is_set():
        try:
            with socket.socket() as listener:
                listener.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
                listener.bind(("127.0.0.1", port))
                listener.listen()
                serve_app(listener, updates, stop)
        except OSError as error:
            print(f"Herdr App status listener: {error}", file=sys.stderr, flush=True)
            stop.wait(RETRY_INTERVAL)


def main():
    updates = queue.Queue()
    stop = threading.Event()
    for name in (signal.SIGTERM, signal.SIGINT):
        signal.signal(name, lambda *_: stop.set())
    legacy = threading.Thread(target=watch_herdr, args=(updates, stop), daemon=True)
    core = threading.Thread(target=watch_core, args=(updates, stop))
    app = threading.Thread(target=watch_app, args=(updates, stop))
    legacy.start()
    core.start()
    app.start()
    data, terminals = None, []
    app_status = None
    previous = None
    try:
        while not stop.is_set():
            try:
                source, value = updates.get(timeout=0.2)
            except queue.Empty:
                continue
            if source == "herdr":
                data = value
            elif source == "herdr-app":
                terminals = value
            else:
                app_status = value
            previous = emit(data, previous, terminals, app_status)
    finally:
        stop.set()
        core.join()
        app.join()


if __name__ == "__main__":
    main()

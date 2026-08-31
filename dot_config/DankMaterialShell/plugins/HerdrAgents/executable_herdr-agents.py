#!/usr/bin/env python3

import json
import os
import select
import socket
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
    }


def render(data):
    if not data or not data.get("agents"):
        return empty_payload()

    workspaces = {
        item["workspace_id"]: item for item in data.get("workspaces", [])
    }
    tabs = {item["tab_id"]: item for item in data.get("tabs", [])}
    grouped = {status: [] for status in STATUSES}

    for agent in data["agents"]:
        status = agent.get("agent_status", "unknown")
        if status not in grouped:
            status = "unknown"

        workspace = workspaces.get(agent.get("workspace_id"), {})
        tab = tabs.get(agent.get("tab_id"), {})
        tokens = agent.get("tokens") or workspace.get("tokens") or {}
        grouped[status].append(
            {
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
        "count": len(data["agents"]),
        "dominant_status": next(
            (status for status in STATUSES if grouped[status]), "empty"
        ),
        "counts": {status: len(grouped[status]) for status in STATUSES},
        "groups": groups,
    }


def agent_ids(data):
    return {agent["pane_id"] for agent in data.get("agents", [])}


def emit(data, previous):
    output = json.dumps(render(data), ensure_ascii=False)
    if output != previous:
        print(output, flush=True)
    return output


def main():
    previous = None
    while True:
        client = None
        stream = None
        try:
            discovered = snapshot()
            client, stream = subscribe(discovered)
            subscribed_agents = agent_ids(discovered)

            # Generic subscriptions replay existing events before live updates.
            drain_events(client, stream)
            current = snapshot()
            previous = emit(current, previous)
            if subscribed_agents != agent_ids(current):
                continue

            while True:
                if not stream.readline():
                    raise ConnectionError("Herdr event subscription closed")
                drain_events(client, stream)
                current = snapshot()
                previous = emit(current, previous)
                if subscribed_agents != agent_ids(current):
                    break
        except (OSError, ValueError, KeyError, RuntimeError):
            previous = emit(None, previous)
            time.sleep(RETRY_INTERVAL)
        finally:
            if stream is not None:
                stream.close()
            if client is not None:
                client.close()


if __name__ == "__main__":
    main()

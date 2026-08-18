#!/usr/bin/env python3

import html
import json
import os
import select
import socket
import time
from pathlib import Path


COLORS = {
    "idle": "#9ece6a",
    "done": "#7aa2f7",
    "working": "#e0af68",
    "blocked": "#f7768e",
    "unknown": "#565f89",
}
ICONS = {
    "idle": "○",
    "done": "●",
    "working": "●",
    "blocked": "●",
    "unknown": "?",
}
ORDER = ("idle", "done", "working", "blocked", "unknown")
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
            {"id": "waybar:snapshot", "method": "session.snapshot", "params": {}},
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
                "id": "waybar:subscribe",
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


def render(data):
    if not data or not data.get("agents"):
        return {"text": "", "tooltip": "", "class": "empty"}

    workspaces = {item["workspace_id"]: item["label"] for item in data["workspaces"]}
    tabs = {item["tab_id"]: item["label"] for item in data["tabs"]}
    grouped = {status: [] for status in ORDER}

    for agent in data["agents"]:
        status = agent.get("agent_status", "unknown")
        if status not in grouped:
            status = "unknown"
        grouped[status].append(agent)

    parts = []
    tooltip = []
    for status in ORDER:
        agents = grouped[status]
        if not agents:
            continue

        parts.append(
            f'<span color="{COLORS[status]}">{ICONS[status]}</span> {len(agents)}'
        )
        tooltip.append(f"<b>{status.title()} ({len(agents)})</b>")
        for agent in agents:
            workspace = workspaces.get(agent.get("workspace_id"), "?")
            tab = tabs.get(agent.get("tab_id"), "?")
            name = agent.get("terminal_title_stripped") or agent.get("agent", "agent")
            tooltip.append(
                f"{html.escape(workspace)} / {html.escape(tab)}: {html.escape(name)}"
            )

    highest = next(
        (status for status in ("blocked", "working", "done", "idle", "unknown") if grouped[status]),
        "empty",
    )
    return {"text": "  ".join(parts), "tooltip": "\n".join(tooltip), "class": highest}


def agent_ids(data):
    return {agent["pane_id"] for agent in data.get("agents", [])}


def emit(data, previous):
    output = json.dumps(render(data), ensure_ascii=False)
    if output != previous:
        print(output, flush=True)
    return output


previous = None
while True:
    client = None
    stream = None
    try:
        discovered = snapshot()
        client, stream = subscribe(discovered)
        subscribed_agents = agent_ids(discovered)

        # Generic subscriptions replay existing events, so consume that finite burst
        # without reconnecting before reading the authoritative current snapshot.
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

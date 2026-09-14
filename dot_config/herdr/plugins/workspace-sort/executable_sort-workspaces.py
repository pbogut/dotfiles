#!/usr/bin/env python3

import json
import os
import re
import socket
import subprocess
import sys
from datetime import date
from typing import Never


def fail(message: str) -> Never:
    print(f"workspace-sort: {message}", file=sys.stderr)
    raise SystemExit(1)


herdr = os.environ.get("HERDR_BIN_PATH", "herdr")
try:
    result = subprocess.run(
        [herdr, "workspace", "list"],
        check=True,
        capture_output=True,
        text=True,
        timeout=10,
    )
    workspaces = json.loads(result.stdout)["result"]["workspaces"]
except (OSError, subprocess.SubprocessError, json.JSONDecodeError, KeyError) as error:
    fail(f"cannot list workspaces: {error}")


def base_order(workspace):
    branch_date = date.min
    match = re.search(r"(?:^|/)(\d{4}-\d{2}-\d{2})-[^/]+$", workspace["label"])
    if match:
        try:
            branch_date = date.fromisoformat(match[1])
        except ValueError:
            pass
    return branch_date, workspace["label"].casefold(), workspace["workspace_id"]


# Each feature takes the position of its first entry in the date-based order.
groups = {}
for workspace in sorted(workspaces, key=base_order):
    feature = workspace.get("tokens", {}).get("feature", "").casefold()
    key = ("feature", feature) if feature else ("workspace", workspace["workspace_id"])
    groups.setdefault(key, []).append(workspace)
sorted_ids = [
    workspace["workspace_id"]
    for group in groups.values()
    for workspace in group
]
current_ids = [workspace["workspace_id"] for workspace in workspaces]
if sorted_ids == current_ids:
    raise SystemExit(0)

socket_path = os.environ.get("HERDR_SOCKET_PATH")
if not socket_path:
    fail("HERDR_SOCKET_PATH is not set")

request = {
    "id": "plugin:pbogut.workspace-sort",
    "method": "workspace.move_block",
    "params": {"workspace_ids": sorted_ids},
}

try:
    with socket.socket(socket.AF_UNIX, socket.SOCK_STREAM) as connection:
        connection.settimeout(10)
        connection.connect(socket_path)
        connection.sendall((json.dumps(request) + "\n").encode())
        response = b""
        while b"\n" not in response:
            chunk = connection.recv(65536)
            if not chunk:
                break
            response += chunk
            if len(response) > 1024 * 1024:
                fail("API response is too large")
    payload = json.loads(response.split(b"\n", 1)[0])
except (OSError, json.JSONDecodeError) as error:
    fail(f"cannot reorder workspaces: {error}")

if "error" in payload:
    fail(payload["error"].get("message", "workspace.move_block failed"))

#!/usr/bin/env python3

import json
import os
import socket
import subprocess
import sys
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

# Herdr worktrees must remain beside their source workspace. Treat each repo
# group as one sortable item and preserve its existing internal order.
groups = {}
for workspace in workspaces:
    worktree = workspace.get("worktree")
    key = (
        ("repo", worktree["repo_key"])
        if worktree and worktree.get("repo_key")
        else ("workspace", workspace["workspace_id"])
    )
    groups.setdefault(key, []).append(workspace)

ordered_groups = sorted(
    groups.values(),
    key=lambda group: (group[0]["label"].casefold(), group[0]["workspace_id"]),
)
sorted_ids = [
    workspace["workspace_id"]
    for group in ordered_groups
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

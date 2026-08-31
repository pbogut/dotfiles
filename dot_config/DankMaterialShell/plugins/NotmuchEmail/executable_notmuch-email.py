#!/usr/bin/env python3

import base64
import json
import os
import subprocess
import sys
import time
import urllib.parse
from email.utils import parseaddr


INBOX_QUERY = ("tag:inbox",)
UNREAD_QUERY = ("tag:unread", "and", "tag:inbox")
MAX_MESSAGES = 25
MAILS_GO_WEB_URL = "http://localhost:6245"
MESSAGE_ACTIONS = {
    "mark-read": ("-unread",),
    "archive": ("+archive", "-inbox", "-unread"),
}


class NotmuchError(RuntimeError):
    pass


def run_notmuch(*args):
    result = subprocess.run(
        ["notmuch", *args],
        check=False,
        capture_output=True,
        text=True,
    )
    if result.returncode != 0:
        detail = result.stderr.strip()
        if detail:
            print(detail, file=sys.stderr)
        command = args[0] if args else "command"
        raise NotmuchError(f"notmuch {command} failed with exit code {result.returncode}")
    return result.stdout


def count_messages(query):
    output = run_notmuch("count", "--", *query).strip()
    try:
        return int(output)
    except ValueError as error:
        raise NotmuchError("notmuch count returned an invalid value") from error


def flatten_messages(nodes):
    for node in nodes:
        if not isinstance(node, list) or not node:
            continue

        message = node[0]
        if isinstance(message, dict) and message.get("match", True):
            yield message

        replies = node[1] if len(node) > 1 else []
        if isinstance(replies, list):
            yield from flatten_messages(replies)


def sender_name(value):
    value = str(value or "").strip()
    name, address = parseaddr(value)
    return name or address or value or "Unknown sender"


def query_term(prefix, value):
    escaped = value.replace('"', '""')
    return f'{prefix}:"{escaped}"'


def load_messages():
    id_output = run_notmuch(
        "search",
        "--format=json",
        "--output=messages",
        "--sort=newest-first",
        f"--limit={MAX_MESSAGES}",
        "--",
        *INBOX_QUERY,
    )
    try:
        message_ids = json.loads(id_output)
    except json.JSONDecodeError as error:
        raise NotmuchError("notmuch search returned invalid JSON") from error
    if not isinstance(message_ids, list) or not all(
        isinstance(value, str) for value in message_ids
    ):
        raise NotmuchError("notmuch search returned invalid message IDs")
    if not message_ids:
        return []

    id_query = []
    for message_id in message_ids:
        if id_query:
            id_query.append("or")
        id_query.append(query_term("id", message_id))

    show_output = run_notmuch(
        "show",
        "--format=json",
        "--body=false",
        "--entire-thread=false",
        "--decrypt=false",
        "--sort=newest-first",
        "--",
        *id_query,
    )
    try:
        threads = json.loads(show_output)
    except json.JSONDecodeError as error:
        raise NotmuchError("notmuch show returned invalid JSON") from error

    messages = []
    for thread in threads:
        if not isinstance(thread, list):
            continue
        for message in flatten_messages(thread):
            message_id = str(message.get("id") or "").strip()
            if not message_id:
                continue
            headers = message.get("headers") or {}
            tags = message.get("tags") or []
            messages.append(
                {
                    "id": message_id,
                    "sender": sender_name(headers.get("From")),
                    "subject": str(headers.get("Subject") or "(no subject)"),
                    "date": str(message.get("date_relative") or ""),
                    "timestamp": int(message.get("timestamp") or 0),
                    "unread": "unread" in tags,
                }
            )

    messages.sort(key=lambda message: message["timestamp"], reverse=True)
    return messages[:MAX_MESSAGES]


def snapshot():
    return {
        "unread": count_messages(UNREAD_QUERY),
        "inbox": count_messages(INBOX_QUERY),
        "messages": load_messages(),
        "updatedAt": int(time.time()),
        "error": "",
    }


def message_url(message_id):
    encoded_id = base64.b64encode(message_id.encode("utf-8")).decode("ascii")
    return MAILS_GO_WEB_URL + "?" + urllib.parse.urlencode({"q": encoded_id})


def open_message(message_id):
    if not message_id:
        raise ValueError("message ID is required")
    os.execvp("gio", ["gio", "open", message_url(message_id)])


def apply_message_action(action, message_id):
    if not message_id:
        raise ValueError("message ID is required")
    changes = MESSAGE_ACTIONS.get(action)
    if changes is None:
        raise ValueError(f"unknown message action: {action}")
    run_notmuch("tag", *changes, "--", query_term("id", message_id))


def main(argv):
    if argv and argv[0] == "open":
        if len(argv) != 2:
            print("usage: notmuch-email.py open MESSAGE_ID", file=sys.stderr)
            return 2
        try:
            open_message(argv[1])
        except (OSError, ValueError) as error:
            print(f"notmuch-email: {error}", file=sys.stderr)
            return 1
        return 0

    if argv and argv[0] in MESSAGE_ACTIONS:
        if len(argv) != 2:
            print(f"usage: notmuch-email.py {argv[0]} MESSAGE_ID", file=sys.stderr)
            return 2
        try:
            apply_message_action(argv[0], argv[1])
        except (NotmuchError, OSError, ValueError) as error:
            print(f"notmuch-email: {error}", file=sys.stderr)
            return 1
        return 0

    if argv and argv != ["snapshot"]:
        print(
            "usage: notmuch-email.py [snapshot|open|mark-read|archive] [MESSAGE_ID]",
            file=sys.stderr,
        )
        return 2

    try:
        data = snapshot()
        return_code = 0
    except (NotmuchError, OSError) as error:
        data = {
            "unread": 0,
            "inbox": 0,
            "messages": [],
            "updatedAt": int(time.time()),
            "error": str(error),
        }
        return_code = 1

    print(json.dumps(data, ensure_ascii=False, separators=(",", ":")))
    return return_code


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))

#!/usr/bin/env python3
"""London and Dubai times, optionally for a local wall time today."""

import argparse
import json
import os
import re
from datetime import datetime, timezone
from zoneinfo import ZoneInfo


def system_zone():
    name = os.environ.get("TZ", "").removeprefix(":")
    if name and not name.startswith("/"):
        return ZoneInfo(name)
    with open(name or "/etc/localtime", "rb") as source:
        return ZoneInfo.from_file(source)


def snapshot(local_time=None, *, now=None, zone=None):
    zone = zone or system_zone()
    now = (now or datetime.now(timezone.utc)).astimezone(zone)
    selected = now
    note = ""
    if local_time is not None:
        if not re.fullmatch(r"(?:[01]\d|2[0-3]):[0-5]\d", local_time):
            raise ValueError("Enter a time from 00:00 to 23:59.")
        hour, minute = map(int, local_time.split(":"))
        selected = now.replace(hour=hour, minute=minute, second=0, microsecond=0, fold=0)
        roundtrip = selected.astimezone(timezone.utc).astimezone(zone)
        if roundtrip.replace(tzinfo=None) != selected.replace(tzinfo=None):
            raise ValueError("That local time is skipped by today's clock change.")
        if selected.utcoffset() != selected.replace(fold=1).utcoffset():
            note = "This local time occurs twice today; showing the first occurrence."

    result = {
        "localTime": selected.strftime("%H:%M"),
        "localDate": selected.strftime("%Y-%m-%d"),
        "localZone": selected.tzname(),
        "note": note,
        "error": "",
    }
    for key, name in (("london", "Europe/London"), ("dubai", "Asia/Dubai")):
        converted = selected.astimezone(ZoneInfo(name))
        result[key] = {
            "time": converted.strftime("%H:%M"),
            "date": converted.strftime("%Y-%m-%d"),
            "zone": converted.tzname(),
            "dayOffset": (converted.date() - selected.date()).days,
        }
    return result


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    source = parser.add_mutually_exclusive_group()
    source.add_argument("--time", help="Local HH:MM today; omit for live time")
    source.add_argument("--timestamp", type=float, help="Clock tick as Unix seconds")
    args = parser.parse_args()
    try:
        now = datetime.fromtimestamp(args.timestamp, timezone.utc) if args.timestamp is not None else None
        print(json.dumps(snapshot(args.time, now=now)))
        return 0
    except (ValueError, OverflowError, OSError, KeyError) as error:
        print(json.dumps({"error": str(error)}))
        return 1


if __name__ == "__main__":
    raise SystemExit(main())

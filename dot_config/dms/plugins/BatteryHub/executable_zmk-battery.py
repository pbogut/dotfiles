#!/usr/bin/env python3
"""Read the unofficial ZMK dongle battery JSON stream for Battery Hub."""

import glob
import json
import math
import os
import re
import selectors
import sys
import termios
import tty

PORT_PATTERN = re.compile(r"usb-ZMK_Project_(.+)_Dongle_.+")
MAX_LINE = 65536


def discover(directory="/dev/serial/by-id"):
    return sorted(glob.glob(os.path.join(directory, "usb-ZMK_Project_*_Dongle_*")))


def keyboard_name(path):
    match = PORT_PATTERN.fullmatch(os.path.basename(path))
    return match.group(1) if match else os.path.basename(path)


def parse_snapshot(line):
    """None is noise; an empty list is a valid snapshot with no slots."""
    try:
        payload = json.loads(line)
    except (ValueError, UnicodeDecodeError):
        return None
    if not isinstance(payload, dict) or not isinstance(payload.get("peripherals"), list):
        return None
    slots = {}
    for item in payload["peripherals"]:
        if not isinstance(item, dict):
            return None
        slot = item.get("slot")
        if type(slot) is not int or slot < 0 or slot in slots:
            return None
        percent = item.get("percent")
        valid = type(percent) in (int, float) and 0 <= percent <= 100
        slots[slot] = percent if valid and math.isfinite(percent) else None
    return sorted(slots.items())


class Keyboard:
    def __init__(self, path):
        self.path = path
        self.name = keyboard_name(path)
        self.fd = None
        self.slots = None
        self.buffer = b""
        self.discarding = False
        self.error = ""

    def open(self):
        self.fd = os.open(self.path, os.O_RDWR | os.O_NOCTTY | os.O_NONBLOCK)
        tty.setraw(self.fd, termios.TCSANOW)
        attrs = termios.tcgetattr(self.fd)
        attrs[0] &= ~(termios.IXON | termios.IXOFF)
        attrs[2] = (attrs[2] | termios.CLOCAL | termios.CREAD) & ~termios.CRTSCTS
        attrs[4] = attrs[5] = termios.B115200
        termios.tcsetattr(self.fd, termios.TCSANOW, attrs)
        termios.tcflush(self.fd, termios.TCIFLUSH)

    def close(self):
        if self.fd is not None:
            os.close(self.fd)
            self.fd = None
        self.slots = None
        self.buffer = b""
        self.discarding = False

    def feed(self, data):
        changed = False
        for part in data.splitlines(keepends=True):
            self.buffer += part
            if len(self.buffer) > MAX_LINE:
                self.discarding = True
                self.buffer = b""
            if part.endswith(b"\n"):
                if not self.discarding:
                    slots = parse_snapshot(self.buffer)
                    if slots is not None:
                        self.slots = slots
                        changed = True
                self.buffer = b""
                self.discarding = False
            elif self.discarding:
                self.buffer = b""
        return changed

    def rows(self):
        if self.fd is None:
            return []
        base = {"type": "keyboard", "group": self.path, "lowThreshold": 20,
                "charging": None}
        if self.slots is None:
            return [dict(base, name=self.name, percentage=None, status="Waiting for battery data")]
        return [dict(base, name=f"{self.name} slot {slot}", percentage=percent,
                     status=f"Slot {slot}") for slot, percent in self.slots]


def snapshot(keyboards):
    devices = []
    bars = []
    for keyboard in keyboards:
        rows = keyboard.rows()
        devices.extend(rows)
        known = [row for row in rows if row["percentage"] is not None]
        if known:
            lowest = min(known, key=lambda row: row["percentage"])
            bars.append(dict(lowest, name=keyboard.name))
    return {"available": any(k.fd is not None for k in keyboards),
            "devices": devices, "barDevices": bars,
            "error": " ".join(k.error for k in keyboards if k.error)}


def emit(keyboards):
    print(json.dumps(snapshot(keyboards), allow_nan=False), flush=True)


def watch(paths):
    keyboards = [Keyboard(path) for path in dict.fromkeys(paths)]
    with selectors.DefaultSelector() as selector:
        try:
            for keyboard in keyboards:
                try:
                    keyboard.open()
                    selector.register(keyboard.fd, selectors.EVENT_READ, keyboard)
                except (OSError, termios.error) as error:
                    keyboard.close()
                    detail = getattr(error, "strerror", None) or str(error)
                    keyboard.error = f"{keyboard.name}: {detail}. Refresh to retry."
            emit(keyboards)
            while True:
                for key, _ in selector.select(timeout=1):
                    keyboard = key.data
                    try:
                        data = os.read(key.fd, 4096)
                        if not data:
                            raise OSError("Dongle disconnected")
                    except BlockingIOError:
                        continue
                    except OSError:
                        selector.unregister(key.fd)
                        keyboard.close()
                        keyboard.error = f"{keyboard.name}: dongle disconnected. Refresh to reconnect."
                        emit(keyboards)
                        continue
                    if keyboard.feed(data):
                        emit(keyboards)
        finally:
            for keyboard in keyboards:
                keyboard.close()


if __name__ == "__main__":
    if sys.argv[1:] == ["discover"]:
        print(json.dumps(discover()))
    elif sys.argv[1:2] == ["watch"]:
        watch(sys.argv[2:])
    else:
        sys.exit("Usage: zmk-battery.py discover | watch [PORT ...]")

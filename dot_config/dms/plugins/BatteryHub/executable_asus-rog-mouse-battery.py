#!/usr/bin/env python3

import json
import os
import select
import sys
import time
from pathlib import Path


SYSFS_HIDRAW = Path("/sys/class/hidraw")
SUPPORTED_IDS = {
    "0003:00000B05:00001A18": 0,
    "0003:00000B05:00001A1A": 1,
}
REQUEST = bytes((0x00, 0x12, 0x07)) + bytes(62)
RESPONSE_PREFIX = bytes((0x12, 0x07))
RESPONSE_TIMEOUT = 2


class BatteryQueryError(RuntimeError):
    pass


class MouseUnavailable(RuntimeError):
    pass


def read_uevent(path):
    values = {}
    try:
        lines = path.read_text(encoding="utf-8").splitlines()
    except OSError:
        return values

    for line in lines:
        key, separator, value = line.partition("=")
        if separator:
            values[key] = value
    return values


def device_info(path):
    try:
        node_name = Path(path).name
    except TypeError:
        return None
    if not node_name.startswith("hidraw"):
        return None

    uevent = read_uevent(SYSFS_HIDRAW / node_name / "device" / "uevent")
    hid_id = uevent.get("HID_ID", "")
    if hid_id not in SUPPORTED_IDS:
        return None
    if not uevent.get("HID_PHYS", "").endswith("/input0"):
        return None

    return {
        "path": str(Path("/dev") / node_name),
        "name": "ASUS ROG Chakram X",
        "priority": SUPPORTED_IDS[hid_id],
    }


def discover_devices():
    devices = []
    try:
        nodes = SYSFS_HIDRAW.glob("hidraw*")
    except OSError:
        return devices

    for node in nodes:
        info = device_info(Path("/dev") / node.name)
        if info is not None:
            devices.append(info)
    return sorted(devices, key=lambda device: (device["priority"], device["path"]))


def parse_battery_response(response, name):
    if len(response) < 10 or not response.startswith(RESPONSE_PREFIX):
        return None
    if not any(response[4:10]):
        raise MouseUnavailable

    percentage = response[4]
    if percentage > 100:
        raise BatteryQueryError("invalid battery percentage")
    low_threshold = response[6] if response[6] <= 100 else 0
    return {
        "name": name,
        "type": "mouse",
        "percentage": percentage,
        "charging": bool(response[9]),
        "lowThreshold": low_threshold,
    }


def query_battery(path, name):
    try:
        descriptor = os.open(path, os.O_RDWR | os.O_NONBLOCK)
    except OSError as error:
        raise BatteryQueryError(error.strerror or str(error)) from error

    try:
        for _ in range(16):
            try:
                if not os.read(descriptor, 64):
                    break
            except BlockingIOError:
                break

        try:
            written = os.write(descriptor, REQUEST)
        except OSError as error:
            raise BatteryQueryError(error.strerror or str(error)) from error
        if written != len(REQUEST):
            raise BatteryQueryError("incomplete HID request")

        deadline = time.monotonic() + RESPONSE_TIMEOUT
        while True:
            remaining = deadline - time.monotonic()
            if remaining <= 0:
                raise BatteryQueryError("battery query timed out")

            readable, _, _ = select.select([descriptor], [], [], remaining)
            if not readable:
                raise BatteryQueryError("battery query timed out")

            try:
                response = os.read(descriptor, 64)
            except BlockingIOError:
                continue
            device = parse_battery_response(response, name)
            if device is not None:
                return device
    except OSError as error:
        raise BatteryQueryError(error.strerror or str(error)) from error
    finally:
        os.close(descriptor)


def payload(available=False, path="", devices=None, error="", missing=False):
    return {
        "available": available,
        "path": path,
        "devices": devices or [],
        "error": error,
        "missing": missing,
    }


def discover():
    candidates = discover_devices()
    if not candidates:
        return payload(), 0

    errors = []
    unavailable = None
    for candidate in candidates:
        try:
            device = query_battery(candidate["path"], candidate["name"])
            return payload(True, candidate["path"], [device]), 0
        except MouseUnavailable:
            unavailable = unavailable or candidate
        except BatteryQueryError as error:
            errors.append(str(error))

    if unavailable is not None:
        return payload(True, unavailable["path"]), 0

    candidate = candidates[0]
    return payload(
        True,
        candidate["path"],
        error="Could not read ASUS ROG Chakram X: " + errors[0],
    ), 1


def read_cached(path):
    info = device_info(path)
    if info is None:
        return payload(missing=True), 0

    try:
        device = query_battery(info["path"], info["name"])
    except MouseUnavailable:
        return payload(True, info["path"]), 0
    except BatteryQueryError as error:
        return payload(
            True,
            info["path"],
            error="Could not read ASUS ROG Chakram X: " + str(error),
        ), 1
    return payload(True, info["path"], [device]), 0


def main(argv):
    if argv == ["discover"]:
        result, return_code = discover()
    elif len(argv) == 2 and argv[0] == "read":
        result, return_code = read_cached(argv[1])
    else:
        print(
            "usage: asus-rog-mouse-battery.py discover|read HIDRAW_PATH",
            file=sys.stderr,
        )
        return 2

    print(json.dumps(result, separators=(",", ":")))
    return return_code


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))

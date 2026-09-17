import importlib.util
import json
import os
from pathlib import Path
import pty
import select
import subprocess
import sys
import tempfile
import unittest


SOURCE = Path(__file__).resolve().parents[3] / (
    "dot_config/DankMaterialShell/plugins/BatteryHub/executable_zmk-battery.py"
)
spec = importlib.util.spec_from_file_location("zmk_battery", SOURCE)
zmk = importlib.util.module_from_spec(spec)
spec.loader.exec_module(zmk)


class ReaderTests(unittest.TestCase):
    def test_discovery(self):
        with tempfile.TemporaryDirectory() as directory:
            for name in ["usb-ZMK_Project_Kyria_Dongle_abc-if00",
                         "usb-ZMK_Project_Other_Board_Dongle_def-if00",
                         "usb-Unrelated_Dongle_ghi-if00"]:
                Path(directory, name).touch()
            paths = zmk.discover(directory)
            self.assertEqual([zmk.keyboard_name(p) for p in paths], ["Kyria", "Other_Board"])

    def test_slot_validation(self):
        self.assertEqual(zmk.parse_snapshot(
            '{"peripherals":[{"slot":8,"percent":0},{"slot":2,"percent":100}]}'),
            [(2, 100), (8, 0)])
        for percent in [None, True, "12", -1, 101, float("nan"), float("inf")]:
            self.assertEqual(zmk.parse_snapshot(json.dumps(
                {"peripherals": [{"slot":0, "percent": percent}]})), [(0, None)])
        for line in ["noise", "[]", "null", '{"peripherals":[null]}',
                     '{"peripherals":[{"slot":true}]}',
                     '{"peripherals":[{"slot":0},{"slot":0}]}']:
            self.assertIsNone(zmk.parse_snapshot(line))

    def test_chunks_many_slots_and_independent_minima(self):
        a = zmk.Keyboard("/dev/serial/by-id/usb-ZMK_Project_A_Dongle_1")
        b = zmk.Keyboard("/dev/serial/by-id/usb-ZMK_Project_B_Dongle_2")
        a.fd = b.fd = 123  # Connected for pure snapshot checks; no I/O.
        self.assertEqual(zmk.snapshot([a])["devices"][0]["status"], "Waiting for battery data")
        message = json.dumps({"peripherals": [
            {"slot": i * 2, "percent": i * 5} for i in reversed(range(12))
        ]}).encode() + b"\n"
        self.assertFalse(a.feed(b"boot log\n" + message[:20]))
        self.assertTrue(a.feed(message[20:]))
        b.feed(b'{"peripherals":[{"slot":1,"percent":42},{"slot":8}]}\n')
        state = zmk.snapshot([a, b])
        self.assertEqual(len(state["devices"]), 14)
        self.assertEqual([d["percentage"] for d in state["barDevices"]], [0, 42])
        self.assertEqual(state["devices"][0]["name"], "A slot 0")
        a.feed(b"x" * (zmk.MAX_LINE + 1))
        a.feed(b'junk\n{"peripherals":[{"slot":50,"percent":63}]}\n')
        self.assertEqual(a.slots, [(50, 63)])
        a.feed(b'{"peripherals":[]}\n')
        self.assertEqual(zmk.snapshot([a])["devices"], [])

    def test_disconnect_requires_new_discovery_and_reader(self):
        with tempfile.TemporaryDirectory() as directory:
            master, slave = pty.openpty()
            path = Path(directory, "usb-ZMK_Project_Kyria_Dongle_test")
            path.symlink_to(os.ttyname(slave))
            # A matching non-serial port must not take down the healthy reader.
            Path(directory, "usb-ZMK_Project_Broken_Dongle_test").touch()
            process = subprocess.Popen([sys.executable, str(SOURCE), "watch", *zmk.discover(directory)],
                                       stdout=subprocess.PIPE, stderr=subprocess.PIPE)
            try:
                def receive():
                    self.assertTrue(select.select([process.stdout], [], [], 3)[0], "No helper output")
                    return json.loads(process.stdout.readline())

                initial = receive()
                self.assertTrue(initial["available"])
                self.assertIn("Broken:", initial["error"])
                os.write(master, b'{"peripherals":[{"slot":0,"percent":23}]}\n')
                self.assertEqual(receive()["barDevices"][0]["percentage"], 23)
                os.close(master)
                master = None
                state = receive()
                self.assertFalse(state["available"])
                self.assertEqual(state["devices"], [])
                master, new_slave = pty.openpty()
                os.close(slave)
                slave = new_slave
                path.unlink()
                path.symlink_to(os.ttyname(slave))
                os.write(master, b'{"peripherals":[{"slot":0,"percent":99}]}\n')
                self.assertFalse(select.select([process.stdout], [], [], 1.2)[0])
                process.terminate()
                process.communicate(timeout=3)
                process = subprocess.Popen([sys.executable, str(SOURCE), "watch", *zmk.discover(directory)],
                                           stdout=subprocess.PIPE, stderr=subprocess.PIPE)
                self.assertTrue(receive()["available"])
                os.write(master, b'{"peripherals":[{"slot":0,"percent":77}]}\n')
                self.assertEqual(receive()["barDevices"][0]["percentage"], 77)
            finally:
                process.terminate()
                process.communicate(timeout=3)
                if master is not None:
                    os.close(master)
                os.close(slave)


if __name__ == "__main__":
    unittest.main()

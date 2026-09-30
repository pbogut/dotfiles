import importlib.util
import io
import json
import os
import unittest
from contextlib import redirect_stdout
from datetime import datetime, timezone
from pathlib import Path
from unittest.mock import patch
from zoneinfo import ZoneInfo


SOURCE = Path(__file__).resolve().parents[3] / "dot_config/DankMaterialShell/plugins/WorldClock/executable_world-clock.py"
spec = importlib.util.spec_from_file_location("world_clock", SOURCE)
assert spec is not None and spec.loader is not None
clock = importlib.util.module_from_spec(spec)
spec.loader.exec_module(clock)


class WorldClockTests(unittest.TestCase):
    def at(self, iso, local_time=None, zone="Europe/Warsaw"):
        return clock.snapshot(local_time, now=datetime.fromisoformat(iso), zone=ZoneInfo(zone))

    def test_summer_and_winter_offsets(self):
        for month, uk_time, uk_zone in ((7, "11:00", "BST"), (1, "10:00", "GMT")):
            with self.subTest(month=month):
                result = clock.snapshot(now=datetime(2026, month, 15, 10, tzinfo=timezone.utc), zone=ZoneInfo("Europe/Warsaw"))
                self.assertEqual(result["london"]["time"], uk_time)
                self.assertEqual(result["london"]["zone"], uk_zone)
                self.assertEqual(result["dubai"]["time"], "14:00")

    def test_today_preview_and_exact_minutes(self):
        result = self.at("2026-09-28T10:00:00+00:00", "18:37")
        self.assertEqual(result["localTime"], "18:37")
        self.assertEqual(result["london"]["time"], "17:37")
        self.assertEqual(result["dubai"]["time"], "20:37")

    def test_previous_and_next_day(self):
        early = self.at("2026-09-28T10:00:00+00:00", "00:00")
        late = self.at("2026-09-28T10:00:00+00:00", "23:45")
        self.assertEqual(early["london"]["dayOffset"], -1)
        self.assertEqual(early["london"]["date"], "2026-09-27")
        self.assertEqual(late["dubai"]["dayOffset"], 1)
        self.assertEqual(late["dubai"]["date"], "2026-09-29")

    def test_today_uses_local_date_not_utc_date(self):
        result = self.at("2026-09-28T23:30:00+00:00", "00:15", "Asia/Tokyo")
        self.assertEqual(result["localDate"], "2026-09-29")
        self.assertEqual(result["london"]["date"], "2026-09-28")

    def test_invalid_times(self):
        for value in ("24:00", "12:60", "9:00", "", "12:30;date"):
            with self.subTest(value=value), self.assertRaises(ValueError):
                self.at("2026-09-28T10:00:00+00:00", value)

    def test_spring_gap(self):
        with self.assertRaisesRegex(ValueError, "skipped"):
            self.at("2026-03-29T12:00:00+00:00", "02:30")

    def test_autumn_overlap_uses_first_occurrence(self):
        result = self.at("2026-10-25T12:00:00+00:00", "02:30")
        self.assertIn("first occurrence", result["note"])
        self.assertEqual(result["dubai"]["time"], "04:30")

    def test_preview_uses_offset_at_selected_time(self):
        result = self.at("2026-03-29T12:00:00+00:00", "00:30")
        self.assertEqual(result["dubai"]["time"], "03:30")
        self.assertEqual(result["london"]["time"], "23:30")

    def test_every_slider_step_is_valid_on_an_ordinary_day(self):
        for minutes in range(0, 1440, 15):
            value = f"{minutes // 60:02}:{minutes % 60:02}"
            self.assertEqual(self.at("2026-09-28T12:00:00+00:00", value)["localTime"], value)

    def cli_at(self, tick, wall_time="2026-09-30T06:36:59.980+00:00"):
        timestamp = datetime.fromisoformat(tick).timestamp()
        output = io.StringIO()
        with (
            patch.object(clock, "datetime", wraps=datetime) as mocked_datetime,
            patch.dict(os.environ, {"TZ": "Europe/Warsaw"}),
            patch("sys.argv", [str(SOURCE), "--timestamp", str(timestamp)]),
            redirect_stdout(output),
        ):
            mocked_datetime.now.return_value = datetime.fromisoformat(wall_time)
            self.assertEqual(clock.main(), 0)
            mocked_datetime.now.assert_not_called()
        return json.loads(output.getvalue())

    def test_tick_timestamp_wins_over_early_wall_clock(self):
        result = self.cli_at("2026-09-30T06:37:00+00:00")
        self.assertEqual(result["localTime"], "08:37")
        self.assertEqual(result["london"]["time"], "07:37")
        self.assertEqual(result["dubai"]["time"], "10:37")

    def test_tick_timestamp_crosses_local_midnight(self):
        result = self.cli_at("2026-09-30T22:00:00+00:00")
        self.assertEqual(result["localDate"], "2026-10-01")
        self.assertEqual(result["localTime"], "00:00")
        self.assertEqual(result["london"]["time"], "23:00")
        self.assertEqual(result["london"]["dayOffset"], -1)
        self.assertEqual(result["dubai"]["time"], "02:00")

    def test_tick_timestamp_at_uk_dst_boundaries(self):
        for tick, expected, zone in (
            ("2026-03-29T00:59:00+00:00", "00:59", "GMT"),
            ("2026-03-29T01:00:00+00:00", "02:00", "BST"),
            ("2026-10-25T00:59:00+00:00", "01:59", "BST"),
            ("2026-10-25T01:00:00+00:00", "01:00", "GMT"),
        ):
            with self.subTest(tick=tick):
                result = self.cli_at(tick)
                self.assertEqual(result["london"]["time"], expected)
                self.assertEqual(result["london"]["zone"], zone)

    def test_zero_timestamp_is_not_treated_as_missing(self):
        result = self.cli_at("1970-01-01T00:00:00+00:00")
        self.assertEqual(result["localDate"], "1970-01-01")


if __name__ == "__main__":
    unittest.main()

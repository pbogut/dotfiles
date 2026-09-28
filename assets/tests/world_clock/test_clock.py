import importlib.util
import unittest
from datetime import datetime, timezone
from pathlib import Path
from zoneinfo import ZoneInfo


SOURCE = Path(__file__).resolve().parents[3] / "dot_config/DankMaterialShell/plugins/WorldClock/executable_world-clock.py"
spec = importlib.util.spec_from_file_location("world_clock", SOURCE)
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


if __name__ == "__main__":
    unittest.main()

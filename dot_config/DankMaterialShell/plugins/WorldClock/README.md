# World Clock

Personal DMS plugin for London and Dubai. Add **World Clock** in the DankBar
layout editor after enabling it in Plugins.

- London is shown in the bar by default. Each city's **Show in bar** switch
  is independent and saved in DMS plugin settings.
- With neither city selected, a globe icon keeps the panel accessible.
- The panel always shows both cities, with flags, dates and timezone labels.
- Enter a local `HH:MM` or drag the slider in 15-minute steps to preview today.
  Typing supports exact minutes, including times after the slider's 23:45 end.
- The panel clocks show the preview; the bar clocks always show live time.
- **Now** and reopening the panel return to live time.
- Day labels identify previous-day and next-day results. Python's system
  timezone database handles UK daylight saving and the local timezone.
- A local time skipped by a clock change shows an error. For a local time
  repeated during a clock change, the preview uses the first occurrence and
  displays a note.

The daemon refreshes on minute changes and after resume, sharing one live
snapshot across bar instances. Panel previews are debounced and discard stale
responses when a newer time is selected.

## Validation

From the chezmoi source root:

```sh
PYTHONDONTWRITEBYTECODE=1 python3 -m unittest discover -s assets/tests/world_clock -v
qmllint -I /usr/share/quickshell/dms dot_config/DankMaterialShell/plugins/WorldClock/*.qml
jq empty dot_config/DankMaterialShell/plugins/WorldClock/plugin.json
```

Runtime status and refresh:

```sh
dms ipc call plugins status worldClock
dms ipc call world-clock status
dms ipc call world-clock refresh
```

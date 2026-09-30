# Calendar

A date-only DankBar widget that opens the built-in DankDash overview, including
its calendar. Add **Calendar** through the DankBar layout editor after enabling
it in Plugins.

- Horizontal bars show a calendar icon and a local date such as `Wed, Sep 30`.
- Vertical bars stack the icon, month and day.
- Clicking toggles the existing DankDash panel. Opening selects Overview.
- The panel uses the clicked widget's screen, bar position and spacing.
- The date refreshes each minute and after resume.

The widget uses DMS's shared DankDash loader and `PopoutService`; it does not
create a separate calendar panel or need a helper process.

## Validation

From the chezmoi source root:

```sh
qmllint -I /usr/share/quickshell/dms dot_config/DankMaterialShell/plugins/Calendar/CalendarWidget.qml
jq empty dot_config/DankMaterialShell/plugins/Calendar/plugin.json
```

After deploying:

```sh
dms ipc call plugins enable calendar
dms ipc call plugins status calendar
```

Once placed in DankBar, click to open Overview and click again to close it.

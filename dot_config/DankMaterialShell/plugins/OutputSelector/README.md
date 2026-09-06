# Output Selector

Niri-only DankBar widget for selecting a single output or toggling multiple
outputs independently. Requires DMS 1.5.3 or newer.

Enable **Output Selector** in DMS Plugins, then add it in the DankBar layout
editor. It supports horizontal and vertical bars and hides when fewer than two
monitors are physically connected. Disabled but connected monitors stay in the
list. The bar shows the active/connected count.

## Modes

- **Single:** selecting a monitor enables it, confirms it is active, and then
  disables the others. Entering Single keeps the monitor hosting the clicked
  widget. Newly connected monitors are turned off until selected; niri may
  briefly activate them before the connection event is handled.
- **Multiple:** toggle each monitor independently. Entering Multiple does not
  automatically enable other monitors. The last active monitor cannot be
  disabled through the widget.

The mode is saved in DMS plugin settings. First use defaults to Multiple without
changing an existing active setup. With a saved Single preference, startup keeps
the focused active monitor, falling back to another active monitor if needed.
If the selected monitor disappears, the plugin prefers the built-in panel, then
another connected monitor. If all outputs become disabled, it attempts to enable
a remaining one. Failed operations show an error rather than retrying forever.

The selection and full layout are not persisted. Output commands are temporary;
resolution, scale, positioning, refresh rate, and niri configuration are not
edited. Changes made through other display tools or a niri configuration reload
are reflected in the widget. Single mode is enforced on selection and physical
topology changes, not continuously against other tools.

One shared daemon owns switching, so turning off the monitor hosting a widget
does not interrupt its operation. Commands use argument arrays and fresh output
queries before changing a monitor. A confirmation timeout leaves the previous
output enabled if the replacement never activates. If a cable disappears during
the switch, the daemon attempts to restore a remaining output. Failed hardware
activation cannot be guaranteed to recover automatically.

## Validation

Run from the chezmoi source directory:

```sh
node --test dot_config/DankMaterialShell/plugins/OutputSelector/tests/controller.test.cjs
jq empty dot_config/DankMaterialShell/plugins/OutputSelector/plugin.json
qmllint -I /usr/share/quickshell/dms dot_config/DankMaterialShell/plugins/OutputSelector/OutputSelectorDaemon.qml dot_config/DankMaterialShell/plugins/OutputSelector/OutputSelectorWidget.qml
dms ipc call plugins status outputSelector
dms ipc call output-selector status
```

The controller tests simulate niri and never alter real outputs. Runtime status
reports the current mode, busy/error state, and connected monitor labels without
hardware serial numbers. Physical switching and cable tests should be performed
interactively, not as part of unattended verification.

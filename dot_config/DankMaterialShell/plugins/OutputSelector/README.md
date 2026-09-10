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
are reflected in the widget. Single mode is enforced on selection, cycling, and
physical topology changes, not continuously against other tools.

One shared daemon owns switching, so turning off the monitor hosting a widget
does not interrupt its operation. Commands use argument arrays and fresh output
queries before changing a monitor. A confirmation timeout leaves the previous
output enabled if the replacement never activates. If a cable disappears during
the switch, the daemon attempts to restore a remaining output. Failed hardware
activation cannot be guaranteed to recover automatically.

## Focus preservation

Single-monitor selection, entering Single mode, and keyboard cycling keep the
current window and workspace active on the destination. Each switch reads fresh
niri state before changing outputs and captures stable IDs, so workspace
renumbering and delayed DMS focus updates do not change the restoration target.
The selector popout closes when a focus-preserving switch starts to release its
keyboard grab.

After the output changes are confirmed, the daemon waits for workspace migration
and restores the original window. If it closed, the daemon restores its workspace.
If niri discarded the workspace, the daemon selects an empty workspace on the
destination instead. Independent toggles in Multiple mode retain niri's normal
focus behavior.

The daemon stays busy until fresh niri queries confirm the restored focus. Rapid
clicks are ignored and repeated cycle requests return `BUSY`; requests are not
queued and cannot overwrite the captured focus. Each subsequent accepted switch
captures fresh focus again. Callbacks and retries from a disposed controller or
an earlier switch cannot issue new focus actions.

Focus restoration has a three-second polling deadline, with bounded query
timeouts. A failed restoration reports an error while retaining a successful
monitor and mode change. Failure to read the initial focus aborts the switch
before changing outputs.

## Keyboard cycling

Bind this command to a keyboard shortcut:

```sh
dms ipc call output-selector cycle
```

It selects the next connected monitor in connector-name order, including disabled
monitors, and wraps around at the end. It advances from the active monitor, or the
focused active monitor when several are on. If focus is unavailable, it uses the
first active monitor in that order. The command reads fresh output state rather
than relying on a previous selection.

Cycling works in either mode and saves Single mode after success. The next monitor
is enabled and confirmed before the others are disabled. With one connected
monitor, it keeps that monitor on or enables it; with none, it does nothing.

`CYCLE_STARTED` means the request was accepted, not that switching has finished.
Further requests return `BUSY` while a switch or focus restoration is running.
`NIRI_REQUIRED` and `NOT_READY` mean the command is unavailable. Check
`dms ipc call output-selector status` for completion and errors. The command also
works when the widget is hidden or not placed in a bar, as long as the plugin is
enabled.

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

DMS 1.5.3 can retain imported JavaScript after `plugins reload`. If a controller
change is still missing from runtime status after reloading the plugin, use
`dms restart` to clear the cached controller.

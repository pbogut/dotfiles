# DMS Agent Instructions

## Scope

This subtree manages DankMaterialShell (DMS) configuration. Files under this
directory are chezmoi sources for `~/.config/DankMaterialShell`.

- Edit sources here, never deployed files under `~/.config/DankMaterialShell`.
- Do not modify the installed DMS files under `/usr/share/quickshell/dms`.
- Do not scan the whole dotfiles repository to learn the DMS plugin API. Start
  with the local and installed references listed below.
- DMS settings and bar layout are not currently managed by chezmoi. Do not
  import or edit the full DMS settings file unless the user explicitly asks.

## Known Environment

The last verified installation was `dms-shell 1.5.3`. Check the active version
before relying on this number because the plugin API is experimental:

```sh
dms version
```

DMS discovers user plugins from:

```text
~/.config/DankMaterialShell/plugins/
```

The matching chezmoi source directory is:

```text
dot_config/DankMaterialShell/plugins/
```

## Read These First

Use these files instead of searching broadly:

```text
/usr/share/quickshell/dms/PLUGINS/README.md
/usr/share/quickshell/dms/PLUGINS/plugin-schema.json
/usr/share/quickshell/dms/PLUGINS/ExampleCompositePlugin/
/usr/share/quickshell/dms/Modules/Plugins/PluginComponent.qml
/usr/share/quickshell/dms/Modules/Plugins/PopoutComponent.qml
/usr/share/quickshell/dms/Modules/Plugins/PluginPopout.qml
/usr/share/quickshell/dms/Services/PluginService.qml
/usr/share/quickshell/dms/Widgets/PluginGlobalVar.qml
```

Local reference implementations:

```text
plugins/HerdrAgents/
plugins/NotmuchEmail/
```

Use `HerdrAgents` as the reference for a composite plugin with a long-running
helper, daemon-owned state, horizontal and vertical pills, and a detailed
popout. Use `NotmuchEmail` as the reference for periodic commands through
`Proc.runCommand`, a scrollable list popout, custom IPC, and opening an item in
an external application.

## Plugin Structure

For a widget with one shared data source, prefer a composite plugin:

```text
plugins/PluginName/
├── plugin.json
├── PluginNameDaemon.qml
├── PluginNameWidget.qml
└── executable_plugin-helper.py   # only when a helper is useful
```

The manifest normally contains:

```json
{
  "id": "pluginName",
  "name": "Plugin Name",
  "description": "Short description",
  "version": "1.0.0",
  "author": "Pawel Bogut",
  "type": "composite",
  "capabilities": ["daemon", "dankbar-widget"],
  "components": {
    "daemon": "./PluginNameDaemon.qml",
    "widget": "./PluginNameWidget.qml"
  },
  "icon": "material_icon_name",
  "requires_dms": ">=1.5.0",
  "dependencies": [],
  "permissions": ["process"]
}
```

Use the installed JSON schema for the authoritative manifest fields. A
composite daemon is instantiated once. Its widget is instantiated for each bar
placement and screen.

## QML Conventions

- Root daemon and widget components should use `PluginComponent`.
- Publish daemon state with
  `pluginService.setGlobalVar(pluginId, "name", value)`.
- Read shared state in widgets with `PluginGlobalVar`.
- Use `Proc.runCommand` for short commands whose output is needed.
- Use `Process` with `SplitParser` for a long-running JSON-lines helper.
- Use `Quickshell.execDetached` for fire-and-forget user actions.
- Pass command arguments as arrays. Do not interpolate message data, paths, or
  other external values into `sh -c` commands.
- Provide both `horizontalBarPill` and `verticalBarPill` unless the user only
  uses one bar orientation.
- Set `popoutContent` to a `PopoutComponent`. A normal left click opens it
  automatically when `pillClickAction` is not set.
- Use `pillRightClickAction` for a direct secondary action when useful.
- Use `Theme`, `StyledText`, `StyledRect`, `DankIcon`, `DankActionButton`, and
  `DankFlickable` to match DMS styling.
- `StyledText` renders plain text, so it is suitable for external labels such
  as email subjects.
- Keep runtime state in global variables. Keep persistent preferences in plugin
  settings only when the feature needs user configuration.

Chezmoi removes the `executable_` prefix from helper targets and gives them
executable permissions. A source named `executable_plugin-helper.py` becomes
`plugin-helper.py`. QML must resolve the deployed name:

```qml
readonly property string helperUrl: Qt.resolvedUrl("./plugin-helper.py").toString()
readonly property string helperPath: decodeURIComponent(helperUrl.replace(/^file:\/\//, ""))
```

## Bar Placement

Enabling a plugin does not add it to DankBar. DMS 1.5.3 stores bar layout in the
array-valued `barConfigs` setting, and the settings IPC refuses to modify arrays
or objects.

Inspect the current layout with:

```sh
dms ipc call settings get barConfigs
```

The user normally places a new widget through DMS Settings, under the DankBar
layout editor. Do not directly patch the deployed settings file or bring all
DMS settings under chezmoi just to place one widget.

## Validation

Validate only the files involved in the change.

Check a manifest:

```sh
jq empty dot_config/DankMaterialShell/plugins/PluginName/plugin.json
```

Check QML against the installed DMS imports:

```sh
qmllint -I /usr/share/quickshell/dms dot_config/DankMaterialShell/plugins/PluginName/PluginNameDaemon.qml
qmllint -I /usr/share/quickshell/dms dot_config/DankMaterialShell/plugins/PluginName/PluginNameWidget.qml
```

Run helpers directly before loading the plugin. When helpers return private
metadata, pipe their output into a schema-only `jq` assertion instead of
printing subjects, senders, paths, or message bodies.

Check the patch for whitespace errors:

```sh
git diff --check -- dot_config/DankMaterialShell/plugins/PluginName
```

## Scoped Deployment

Preview and apply only the plugin being changed. Do not run an unqualified
`chezmoi apply`.

Resolve target names when needed:

```sh
chezmoi target-path dot_config/DankMaterialShell/plugins/PluginName/plugin.json
chezmoi target-path dot_config/DankMaterialShell/plugins/PluginName/executable_plugin-helper.py
```

For a new plugin, create its managed target directory first, then apply its
files explicitly:

```sh
chezmoi apply ~/.config/DankMaterialShell/plugins/PluginName
chezmoi apply \
  ~/.config/DankMaterialShell/plugins/PluginName/plugin.json \
  ~/.config/DankMaterialShell/plugins/PluginName/PluginNameDaemon.qml \
  ~/.config/DankMaterialShell/plugins/PluginName/PluginNameWidget.qml \
  ~/.config/DankMaterialShell/plugins/PluginName/plugin-helper.py
```

Omit the helper target when the plugin has no helper. Confirm that deployed
content matches the source:

```sh
chezmoi diff \
  ~/.config/DankMaterialShell/plugins/PluginName/plugin.json \
  ~/.config/DankMaterialShell/plugins/PluginName/PluginNameDaemon.qml \
  ~/.config/DankMaterialShell/plugins/PluginName/PluginNameWidget.qml
```

## Runtime Commands

Use DMS IPC instead of restarting the whole shell:

```sh
dms ipc call plugin-scan list
dms ipc call plugins enable pluginName
dms ipc call plugins reload pluginName
dms ipc call plugins status pluginName
```

The plugin directory watcher discovers new manifests. Component edits still
need a plugin reload. Use `dms restart` only if plugin reload cannot recover.

A daemon may expose a small custom `IpcHandler` for refresh and status checks.
For example, NotmuchEmail provides:

```sh
dms ipc call notmuch-email refresh
dms ipc call notmuch-email status
```

## Existing Plugins

`herdrAgents` is a composite daemon and DankBar widget. Its helper emits
JSON-lines, the daemon publishes global state, and the widget shows agent and
quota data in a popout.

`notmuchEmail` is a composite daemon and DankBar widget. It uses these queries:

```text
Unread count: tag:unread and tag:inbox
Inbox count and rows: tag:inbox
```

Its helper requests headers with `notmuch show --body=false`, publishes at most
25 individual messages, and never puts message bodies or filenames in DMS
state. A row click opens the message through the existing mails-go-web service.
Do not inspect encrypted Notmuch or mail-account configuration for normal
widget work.

## Completion Checklist

1. Read the installed plugin docs and the closest local plugin example.
2. Make the smallest source change under this directory.
3. Validate the manifest, helper, and QML.
4. Preview and apply only the changed plugin targets.
5. Enable or reload the plugin through IPC.
6. Verify plugin status and any custom status IPC.
7. Tell the user to place a new widget in DankBar settings when required.

# OpenCode 2 reporting to Herdr

The integration files are pinned in `.chezmoiexternal.toml` to Herdr 0.9.5,
commit `2ecf19a92fc3a7fff75b6ce3655ef04f4625ec01`, integration version 13.
Update the three URLs together when upgrading the integration.

`dot_config/opencode/private_cli.json` registers `./herdr-opencode`. Its
`tui.js` entrypoint loads `herdr-tui-session.js`. In OpenCode 2, that TUI plugin
reports both lifecycle state and the selected root session. It filters shared
server events by the pane's selected session family. It also handles pending
permissions and forms from subagents.

The accompanying server entrypoint is part of the official integration. Its v2
`setup` is a no-op; the TUI owns v2 reporting. Mini and headless v2 clients do
not run this TUI plugin.

Herdr 0.9.5's installer and status checker require both TUI registrations.
`dot_config/opencode/private_tui.jsonc` keeps its one-entry compatibility
registration; OpenCode 2 uses the registration in `cli.json`.

Reports retain `agent: opencode`, `source: herdr:opencode`, and the root session
ID. The existing project-layout session cache uses those fields for reopening
the correct conversation.

## Tests

```sh
node --test assets/tests/herdr_project_layout/opencode_session.test.mjs
```

The tests require Node.js and chezmoi. They load the pinned external source with
`chezmoi cat`, rather than reading an installed plugin. The first run needs
network access to fetch the source; subsequent runs can use chezmoi's cache.
They use a temporary Herdr socket and a simulated v2 client to check startup
hydration, lifecycle events, child requests, session switching, shared-server
isolation, stale cache updates, disposal, and operation outside Herdr.

## Apply

```sh
chezmoi diff \
  ~/.config/opencode/herdr-tui-session.js \
  ~/.config/opencode/herdr-opencode/tui.js \
  ~/.config/opencode/plugins/herdr-agent-state.js \
  ~/.config/opencode/tui.jsonc \
  ~/.config/opencode/cli.json
chezmoi apply --parent-dirs \
  ~/.config/opencode/herdr-tui-session.js \
  ~/.config/opencode/herdr-opencode/tui.js \
  ~/.config/opencode/plugins/herdr-agent-state.js
chezmoi apply ~/.config/opencode/tui.jsonc ~/.config/opencode/cli.json
```

Quit and reopen the OpenCode TUI inside Herdr to load the integration.

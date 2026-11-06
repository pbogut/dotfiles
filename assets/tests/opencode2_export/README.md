# OpenCode 2 temporary export

Run from the chezmoi source directory with Node.js 24 or newer:

```sh
node --test assets/tests/opencode2_export/*.test.mjs
```

The formatter tests cover v2 message types, hidden reasoning/tools, complete
turn timing, idle markers, and sessions without idle markers. The command
tests use a temporary test editor to check the full-session export call,
quoted editor arguments, file cleanup, asynchronous TUI suspend/resume,
failure handling, and repeated key presses.

The TUI-only plugin lives in `dot_config/opencode2/extensions/temp-export`.
Its options in `private_cli.json` match the v1 plugin: timestamps, turn
durations, and agent/model metadata on; thinking and tool details off.

Apply the plugin before its CLI registration:

```sh
chezmoi apply --parent-dirs --source-path \
  dot_config/opencode2/extensions/temp-export/package.json \
  dot_config/opencode2/extensions/temp-export/transcript.ts \
  dot_config/opencode2/extensions/temp-export/tui.ts
chezmoi apply --source-path \
  run_onchange_before_prepare-opencode2-lsp.sh.tmpl \
  dot_config/opencode2/private_cli.json
```

Quit and reopen `oc2` to load the TUI plugin. `Ctrl+X`, then `Y` opens the
custom temporary transcript in `$EDITOR`; closing the editor removes the
temporary file. The built-in export keeps its default `Ctrl+X`, then `X`.

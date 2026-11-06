# OpenCode 2 LSP sidebar

`sidebar.patch` extends `christensenjairus/opencode-v2-lsp-support` at commit
`4a17bc8379e572ab104ec26b55f92ee9b51dce37`. Upstream code and its MIT license
stay in the installed checkout, outside chezmoi.

The patch adds location-scoped status RPC and a TUI sidebar section. Servers
start on demand. The sidebar shows starting, running, and failed servers, or
`No active language servers` when empty. It adds no warnings for unconfigured
languages. Running means the initialization handshake succeeded, not that the
project has no diagnostics.

Click the header to collapse or expand the list. It starts expanded and saves
the preference in OpenCode's plugin storage. Only the collapsed header shows
the running-server count, for example `▶ LSP (2 active)`. The count continues
updating while collapsed; starting and failed servers are not counted.

## Apply

From the chezmoi source directory:

```sh
chezmoi apply --source-path \
  run_onchange_before_prepare-opencode2-lsp.sh.tmpl \
  dot_config/opencode2/private_opencode.jsonc.tmpl
```

The before-hook hashes the patch, rendered server config, and CLI config. It
runs on the next apply that includes the hook when any hash changes. A normal
full apply includes it; applying only a config file does not. It is not a file
watcher.

When also changing CLI settings, add `dot_config/opencode2/private_cli.json`
to that scoped apply.

The installer needs Git, Node.js 24+, and `flock`. It downloads the pinned
revision, checks and applies the patch, and runs the dependency-free tests.
Only a successful installation becomes `~/.local/share/opencode2/plugins/lsp`.
Versioned installations live under the adjacent `lsp-builds` directory. A
config-only change reuses the existing build. Failed installations leave the
previous symlink intact. Old builds are retained for rollback.

The OpenCode config references the versioned directory directly. Its path
includes the patch checksum, so patch updates change the config too. This
avoids OpenCode's directory watcher rejecting the `lsp` symlink or retaining
a stale plugin after it is switched. The symlink remains a convenience alias.

Run `oc2 reload` in the project afterward. Quit and reopen the TUI if it has
not picked up the new sidebar part. The installer does not restart sessions.

## Update the patch

Use a disposable upstream checkout at the pinned revision. Apply the patch,
make changes there, then replace this patch with the resulting diff. If the
upstream revision changes, update the installer and config pins and recheck
every hunk.
Do not edit the installed checkout or OpenCode's package cache.

The patched checkout contains:

- `node test-opencode-lsp.js`: existing diagnostics/navigation coverage plus
  status lifecycle, failure, shutdown, and location isolation tests.
- `node --test test-status-view.js`: event filtering, stale responses,
  RPC failure/reload recovery, and subscription disposal.
- `test-sidebar.tsx`: actual OpenTUI rendering, click-to-collapse, saved
  preference, live active counts, and session switching checks.

For the optional sidebar test and type checking, install test dependencies in
the disposable checkout, not in chezmoi:

```sh
npm install --no-save --package-lock=false --ignore-scripts \
  @opencode/plugin@2.2.5 @opentui/core@0.8.2 @opentui/solid@0.8.2 \
  solid-js@1.9.17 @types/node typescript
bun --preload @opentui/solid/preload test-sidebar.tsx
npx --no-install tsc --noEmit --skipLibCheck --strict --module preserve \
  --moduleResolution bundler --allowImportingTsExtensions --target esnext \
  --jsx preserve --jsxImportSource @opentui/solid \
  tui.tsx src/status.ts src/status-view.ts
```

`OPENCODE2_LSP_INSTALL_ROOT` overrides the installation directory when testing
the installer. It does not change the plugin path in the OpenCode config.

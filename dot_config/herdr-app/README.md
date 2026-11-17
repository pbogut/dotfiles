# Herdr App configuration

Chezmoi manages these files. The `pbogut` layout uses bottom tabs and gapless
panes with square 1 px borders when split. The focused pane uses the accent color.
Terminal text matches Alacritty's 12 pt at 16 px.

## Keys

`keys.json` keeps the app's standard shortcuts and adds:

| Key | Action |
| --- | --- |
| Ctrl+G | Bottom shortcut bar |
| Alt+Esc | Copy mode |
| Alt+O | Space/tab picker |
| Alt+T | Toggle sidebar |
| Alt+P / Alt+N | Previous / next tab |

Ctrl+G opens a full-width overlay above the tabs in the terminal area.
It covers the bottom of the terminal without resizing it. Shortcuts use
outlined keycaps in the current theme's colors.
An action or cancellation closes the overlay and returns focus to the terminal.
Prefix bindings live in `mods/pbogut-keys/bindings.js`.

| After Ctrl+G | Action |
| --- | --- |
| c | New tab |
| v / s | Split right / down |
| Escape / Ctrl+G | Cancel |

Alt+Esc opens copy mode directly. Its hints use a single row in the same bottom
overlay. Copy and cancel stay visible on the right; the other hints clip when
space runs out. Neither overlay resizes the terminal, and opening one replaces
the other. Both follow window resizing while open, preserving copy selection.
Copy mode uses the app's terminal selection.
Move with `hjkl`,
start or stop selection with `v`, and select lines with `V`.
Before selection starts, movement highlights only the copy cursor's cell.
Line selection includes indentation and keeps whole lines when moving with
`j` / `k`, including when reversing direction. Horizontal motions leave the
selected lines intact.
`0` and `$` move to line edges. `gg` and `G` move to the history edges.
Ctrl+B and Ctrl+F move a page up or down.
`y` copies and exits. Escape cancels. Exiting clears the
selection and returns to the live screen.

## Named tabs

The `pbogut` layout loads `mods/pbogut-tabs`, a native App mod. These shortcuts
focus the named tab in the current space, or create it and launch its program:

| Key | Tab |
| --- | --- |
| Alt+J | `nvim` |
| Alt+K / Alt+L | `shell` / `shell-2` |
| Alt+; | `dev` |
| Alt+M / Alt+, / Alt+. | `sql` / `rest` / `git` |
| Alt+H / Ctrl+Alt+J | `oc-1` |
| Ctrl+Alt+K / Ctrl+Alt+L / Ctrl+Alt+; | `oc-2` / `oc-3` / `oc-4` |

These override Alt+H/J/K/L pane navigation in this layout. New tabs start in
the space's configured folder. Creating one orders managed tabs as above,
with OpenCode slots in numeric order, then other tabs in their existing order.
Repeated shortcuts only focus existing tabs. They preserve the running program
and its working directory. The initial unnamed tab is retained.
Program-backed tabs replace the launcher's shell with `exec`. Exiting the
program closes its pane, and the tab closes when its last pane exits.
The shortcut creates a fresh tab the next time it is used.

The mod uses the App's `spaces()`, `nextCommand()`, and `run()` APIs. A zero-height
layout block keeps the controller loaded. It waits for a created tab to appear
before processing the next creation request.

Neovim starts through `herdr-app-vim`, with an App-specific socket for its
`HC_TERMINAL_ID`. Multiple Neovim terminals can run in the same space.
The App's lazygit config uses that helper to open files and return to the
named `nvim` tab. The helper resolves that tab's terminal through `herdr-app ls`
and receives `HERDR_APP_HOME` and `HERDR_APP_SPACE_ID` from the mod.
The old TUI uses its existing helpers and separate socket directory.

The `dev` role runs `make dev` when a Makefile exists, then closes without an
Enter prompt. Trusted `herdr-project.sh` commands, project setup/teardown, and
restart restoration are part of the remaining project-workflow migration.

## Checks

Run from the chezmoi source directory:

```sh
herdr-app check dot_config/herdr-app/mods/pbogut-keys
herdr-app check dot_config/herdr-app/mods/pbogut-copy
herdr-app check dot_config/herdr-app/mods/pbogut-tabs
node --experimental-vm-modules --test assets/tests/herdr_app/shortcuts.test.mjs
node --experimental-vm-modules --test assets/tests/herdr_app/named_tabs.test.mjs
python3 assets/tests/herdr_app/keyboard.py
python3 assets/tests/herdr_app/named_tabs.py
python3 assets/tests/herdr_app/editor.py
```

The keyboard test requires Xvfb, xdotool, xclip, and Python's Pillow package with
XCB support for capturing cursor movement between frames.
It starts its own window,
home directory, and core session under `/tmp/opencode`, sends keys only there,
and stops those test processes on exit. Screenshots and logs remain in its
printed sandbox directory.
The named-tab test uses Zsh and harmless stand-in role programs, including
successful and failed exits and recreating a closed tab. It also verifies
actual SQL, main-editor, and scratch Neovim processes running together,
lazygit file opening, and closing tabs on exit. The editor test uses headless
Neovim servers to check terminal-specific sockets and named-tab routing,
including when an old space-wide lock is still held.

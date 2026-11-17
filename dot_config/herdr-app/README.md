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
| Ctrl+Alt+P | Project picker |
| Ctrl+Shift+P | Command palette |
| Alt+T | Toggle sidebar |
| Alt+P / Alt+N | Previous / next tab |

All three pickers accept Ctrl+J to move down and Ctrl+K to move up while
their search field is focused. Up/Down also work; Enter selects a result.

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

## OpenCode sessions

Each space's `oc-1`, `oc-2`, and other numbered OpenCode tabs remembers its own
selected root conversation. The local OpenCode `herdr-subject` TUI extension
records selections in the core's `pbogut-opencode` document, keyed by space ID
and slot name. Document version checks preserve concurrent updates from other
tabs. Child sessions resolve to their root; visiting Home retains the last
conversation. Unmanaged tabs do not write this cache.

Named tabs launch through `herdr-app-opencode`. It resumes the slot with
`opencode --session <id>`, or starts without a session when the slot is new.
Normal exit closes the tab. Its shortcut recreates it with the saved conversation.
Closing and reopening the App window reconnects to surviving processes.

For a lost process or a reboot, core recovery first creates a replacement shell
in the same terminal. `~/.zshrc.d/herdr-app-opencode.zsh` checks once at that
shell's first prompt. It verifies the root process ID, terminal labels, saved
slot owner, and current tab name, then replaces the shell with OpenCode in the
original project folder. The tab ID, terminal ID, splits, and focus survive.
This automatic recovery requires Zsh to remain the core's recovery shell.
Renamed tabs and nested shells do not trigger restoration.

Run `/reload` in already-open named OpenCode tabs after applying the extension.
It can register their selected conversation without closing them. New tabs load
it automatically. The App launcher clears inherited old-Herdr pane variables;
OpenCode running in Herdr TUI continues using the existing official integration,
title reporting, and workspace-local session caches.

## Projects

Ctrl+Alt+P opens the native `pbogut-projects` popup. Open spaces come first,
followed by projects from `ls-project -f` in its recent-first order. Local
projects already open appear once. Type to search names, full paths, or
directory aliases; multiple search words can match different parts of a path.
Use Up/Down or Ctrl+J/K and Enter, or click a row. Escape closes the picker.

Selecting an open space focuses it. Selecting a project creates a local space
in that directory with its compact project label and an initial shell.
Space matching uses its configured folder, so changing a terminal's working
directory does not cause duplicate spaces. Existing custom space names are shown.

`mods/pbogut-projects/projects.json.tmpl` gets the project root and directory
aliases from chezmoi. The mod reads the rendered JSON and runs the existing
`ls-project` script through the App's `exec()` API. Space creation and selection
use native `run()` commands.

The results use a native virtual list with 48 px rows. It builds the visible
rows and a small buffer, rather than every discovered project. Mouse selection
uses each space ID or project folder, so scrolling and filtering do not change
which project a click opens.

Ctrl+Enter opens a native "New dated worktree" name prompt for the selected
project. Enter or Create runs `~/.scripts/git-new-dated-worktree` from the
repository's `.bare` root, with spaces in the name changed to hyphens, just
like `herdr-project`. The existing script chooses the date prefix and source
branch. On success, the picker opens a space in the new worktree.
Escape or Cancel closes the prompt; creation errors stay in the prompt so
the name can be corrected and retried.

This action uses local `.bare` repositories. Repository paths containing
whitespace are rejected because the existing `git-wt` helper splits its
worktree listing on whitespace. The picker verifies that the script created
a new registered worktree, since its final path output can mask Git failures.

## Space initials

The `pbogut` layout uses `mods/pbogut-spaces`, a copy of Herdr App 0.1.16's
Spaces sidebar. Letter tiles use the repository name from the space's configured
folder. Git's common directory identifies the repository across worktrees:
`gitlab.com/assuredpharmacy/pms/.bare` gives `P`, as does `pms/.git`.
The shortened display name and a terminal's current directory do not affect it.
Folders outside Git use the folder name; a space without a folder uses its name.

Lookups are cached by machine and configured folder and refreshed once a minute
while the window is active. After upgrading Herdr, merge changes from the shipped
Spaces mod into this copy, keeping the configured-folder lookup and tile letter.

## Customized built-in pickers

`mods/pbogut-picker` copies Herdr App 0.1.16's `mods/picker`.
`mods/pbogut-palette` copies its `frame/palette` as a regular native mod.
Alt+O and Ctrl+Shift+K open the customized picker; Ctrl+Shift+P opens the
customized palette. The palette's "Go to space or tab…" entry opens
`pbogut-picker` too.

Both copies add Ctrl+J/K to the existing arrow-key handling. The space/tab
picker wraps at the ends; the palette stops at the ends, matching their
original behavior. The palette has its own recent-command history.

Chezmoi manages these copies because Herdr rewrites shipped mods and frame
screens on startup. After a Herdr upgrade, compare the copies with the new
shipped versions and merge relevant changes. Keep the navigation aliases,
the palette's `pbogut-picker` target, and its local command icon path.
Shared icons still come from Herdr's `mods/workspace-chrome`.

## Checks

Run from the chezmoi source directory:

```sh
herdr-app check dot_config/herdr-app/mods/pbogut-keys
herdr-app check dot_config/herdr-app/mods/pbogut-copy
herdr-app check dot_config/herdr-app/mods/pbogut-tabs
herdr-app check dot_config/herdr-app/mods/pbogut-projects
herdr-app check dot_config/herdr-app/mods/pbogut-picker
herdr-app check dot_config/herdr-app/mods/pbogut-palette
herdr-app check dot_config/herdr-app/mods/pbogut-spaces
node --experimental-vm-modules --test assets/tests/herdr_app/shortcuts.test.mjs
node --experimental-vm-modules --test assets/tests/herdr_app/named_tabs.test.mjs
node --experimental-vm-modules --test assets/tests/herdr_app/space_initials.test.mjs
node --test assets/tests/herdr_app/projects.test.mjs
node --test assets/tests/herdr_app/worktrees.test.mjs
node --test assets/tests/herdr_app/opencode_session.test.mjs
node --test assets/tests/herdr_app/opencode_rpc.test.mjs
python3 assets/tests/herdr_app/keyboard.py
python3 assets/tests/herdr_app/named_tabs.py
python3 assets/tests/herdr_app/opencode_sessions.py
python3 assets/tests/herdr_app/editor.py
python3 assets/tests/herdr_app/projects.py
python3 assets/tests/herdr_app/projects.py --profile
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
The OpenCode test runs the real App/core and local TUI extension with a small
session-cache fixture instead of an OpenCode account. It checks separate slots,
root selection, normal exit/reopening, window reconnection, process loss,
durable core-shutdown recovery, and adoption of existing named tabs.
The project-picker test copies the source `ls-project` script into its sandbox
and checks discovery among 600 projects, alias search, and opening or focusing
native spaces.
It also checks Ctrl+J/K with focused search inputs in all three pickers,
Enter selection, scrolling, virtual-row clicks, and the palette's link to the
customized picker. `--profile` instruments only the sandbox copy and measures
three unfiltered openings. It reports command execution, JavaScript rendering,
and time from initialization to native layout, and asserts that each lazy row
batch stays small. The screenshot timing also includes keyboard injection and
image capture.
The native test also copies `git-new-dated-worktree` and `git-wt` into its
sandbox. It checks Ctrl+Enter, cancellation, dated branch names, the script's
source-branch choice, opening the new space, and retrying after a Git error.

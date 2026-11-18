# Herdr App configuration

Chezmoi manages these files. The `pbogut` layout uses bottom tabs and gapless
panes with square 1 px borders when split. The focused pane uses the accent color.
Terminal text matches Alacritty's 12 pt at 16 px.

Chezmoi selects `pbogut` for the next app launch. `modify_shared.json` sets
the `layout` key in Herdr's `shared.json`, preserving the other saved state.
Choosing another layout in the app lasts until the next chezmoi apply.

## Keys

`keys.json` keeps the app's standard shortcuts and adds:

| Key | Action |
| --- | --- |
| Ctrl+G | Bottom shortcut bar |
| Alt+Esc | Copy mode |
| Alt+O | Spaces picker in sidebar order |
| Alt+I | Agents picker in sidebar order |
| Ctrl+Shift+K | Go to space/tab/agent picker |
| Ctrl+Alt+P | Project picker |
| Ctrl+Shift+P | Command palette |
| Alt+T | Toggle sidebar |
| Alt+P / Alt+N | Previous / next tab |

All five pickers accept Ctrl+J to move down and Ctrl+K to move up while
their search field is focused. Up/Down also work; Enter selects a result.

Ctrl+G opens a full-width overlay over the tab bar, above the status bar.
The terminal stays fully visible without resizing. Shortcuts use
outlined keycaps in the current theme's colors.
An action or cancellation closes the overlay and returns focus to the terminal.
Prefix bindings live in `mods/pbogut-keys/bindings.js`.

| After Ctrl+G | Action |
| --- | --- |
| c | New tab |
| v / s | Split right / down |
| x | Close project with teardown, or normally close an ordinary space |
| Ctrl+G | Send Ctrl+G to the focused terminal |
| Escape | Cancel |

Double Ctrl+G uses `mods/pbogut-keys/send-ctrl-g.mjs`, a Node helper that sends
through Core's attach stream without the `hc keys` quiet-period delay. It reads
the terminal's keyboard mode, preserves its size, and runs outside the shortcut
loop so repeated presses stay responsive. Remote terminals use the local Core's relay.

Alt+Esc opens copy mode directly. Its hints use a single row in the same bottom
overlay. Copy and cancel stay visible on the right; the other hints clip when
space runs out. Neither overlay resizes the terminal, and opening one replaces
the other. Both follow window resizing while open, preserving copy selection.
Copy mode uses the app's terminal selection.
Move with `hjkl`,
start or stop selection with `v`, and select lines with `V`.
`w` moves to the next word start, `e` to the current or next word end, and
`b` to the previous word start. Letters, numbers, and underscores form words;
punctuation forms separate runs. Word motions extend `v` selections and cross
lines and scrollback. They read fresh terminal text through Core, so queued
motions and copying wait for each word move to finish.
Older output marked incomplete by Core does not block movement in retained history.
`W`, `E`, and `B` use whitespace-separated words, keeping paths and URLs together.
Before selection starts, movement highlights only the copy cursor's cell.
Line selection includes indentation and keeps whole lines when moving with
`j` / `k`, including when reversing direction. Horizontal motions leave the
selected lines intact.
`0` and `$` move to line edges. `^` moves to the first non-whitespace character
on the current terminal row. `gg` and `G` move to the history edges.
Ctrl+U and Ctrl+D move half a page up or down, preserving the column.
Ctrl+B and Ctrl+F move a full page. Both extend `v` and `V` selections.
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
the space's configured folder. Tabs use a fixed order:
`nvim`, `shell`, `shell-2`, `dev`, `sql`, `rest`, `git`, `docker`, numbered
`oc-N` slots, then `shell-3`. OpenCode slots sort numerically. Other tabs follow
in their existing relative order. Loading the mod, opening or reloading a project,
and named-tab shortcuts restore this order. Project definitions only choose which
tabs open automatically.
Repeated shortcuts reuse existing tabs. They preserve the running program
and its working directory. Shortcuts retain the initial unnamed tab.
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

In a project, the `dev` role runs the command from `herdr-project.json`.
When `dev` is omitted, or in an ordinary space, it runs `make dev` if a
`Makefile` exists, or exits immediately otherwise.
The tab closes when the command exits, including on failure.
Teardown, tasks, and general command restoration are part of the remaining
project-workflow migration.

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

## DMS agent status

The `pbogut-agent-status` controller stays loaded in the `pbogut` layout.
Herdr refreshes it when its native agent list changes. It sends agent addresses,
displayed statuses and focus flags to the DMS Herdr Agents helper over a persistent
connection to `127.0.0.1:47653`.

It sends a snapshot on connection and whenever those values change. It makes no
CLI calls or periodic status queries. This gives the widget Herdr App's
finished-but-unseen `done` state and its focused-agent badge and sorting.
The helper still gets agent titles and terminal lifecycle events from `hc`.

Closing the app or unloading the controller closes the connection. The widget
then uses core status with no focused app agent. If DMS restarts, the controller
reconnects and sends its current snapshot. Connection failures retry after two
seconds; a connected, unchanged app sends nothing.

Tests can override the port with the mod's `port` prop and the helper's
`HERDR_AGENTS_PORT` environment variable.

## Projects

Ctrl+Alt+P opens the native `pbogut-projects` popup. Open projects come first,
followed by projects from `ls-project -f` in its recent-first order.
The header shows the selected machine, initially the active space's machine.
Tab cycles through this computer and connected machines; Shift+Tab cycles backwards.
Each switch reloads that machine's discovered and open projects, keeps the search text,
and resets the selection. Late responses from previous loads are ignored.
Projects already open on that machine appear once. Type to search names, full
paths, or directory aliases; multiple search words can match different parts of a path.
Use Up/Down or Ctrl+J/K and Enter, or click a row. Escape closes the picker.

Selecting an open project focuses it. Selecting a project creates a space on the
selected machine in that directory with its compact project label. Its shared project definition
supplies the tabs; without one, the App's fallback definition opens `nvim`.
Project matching uses its configured folder, so changing a terminal's working
directory does not cause duplicate spaces. Matching includes the machine, so
identical paths on different hosts stay separate. Existing custom space names are shown.

Only spaces created through this picker are projects, including its dated
worktree action. The controller records their exact space IDs in Herdr's
shared state under `pbogut.projects.spaces`. These markers survive App restarts.
Existing unmarked spaces stay ordinary; there is no automatic conversion.
The picker ignores ordinary spaces, even in a discovered project's directory.
Such a project has no open badge, and selecting it creates a separate project
space. Ordinary spaces remain available through the sidebar and Go to picker.

All `herdr-project.json` behavior applies only to marked projects: names,
initial tabs, dev overrides, setup, teardown, and explicit config reloads.
Ordinary spaces retain their native names and Git branches. Named-tab shortcuts
still work there without reading either the project or fallback definition.

`mods/pbogut-projects/projects.json.tmpl` gets the project root and directory
aliases from chezmoi. The mod reads that machine's rendered JSON and runs its
`ls-project` script through the App's `exec()` API. Remote machines need those
settings and the helper scripts deployed there. Remote paths use that core's
`HOME` and `HERDR_APP_HOME`, falling back to `$XDG_CONFIG_HOME/herdr-app` or
`~/.config/herdr-app`. Lookup failures stay visible under the selected machine;
they never fall back to local results. Creation calls the local
`herdr-app do space.new` API with the target machine and `HERDR_APP_HOME`.
Its response identifies the exact space to mark, even if another space opens
in the same directory concurrently. Selection uses the native `run()` command.

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

This action uses `.bare` repositories on the displayed machine, including its
`git-new-dated-worktree` and `git-wt` helpers. Repository paths containing
whitespace are rejected because the existing `git-wt` helper splits its
worktree listing on whitespace. The picker verifies that the script created
a new registered worktree, since its final path output can mask Git failures.

### Project tab definitions

Put `herdr-project.json` beside `.bare` so sibling worktrees share it:

```text
project/
  .bare/
  herdr-project.json
  main/
  feature/
```

```json
{
  "name": "PMS",
  "tabs": ["nvim", "dev", "oc-1", "oc-2", "shell"]
}
```

The project picker reads the file on the selected machine when opening a project,
including after Ctrl+Enter creates a dated worktree. `tabs` lists named roles to open.
Its list order does not affect display order.
A new space selects the first configured tab. Once creation finishes with a
configured tab present, it removes the temporary initial shell if that tab is
still unnamed and unsplit.

Opening an existing project creates missing configured tabs and reuses those
already running. It preserves existing tabs and the selected tab. Opening the
project again reloads its definition. Tabs always use the fixed role order above.

Ctrl+Shift+P → **Reload project config** applies the definition again to the
current project, using that space's machine and configured folder. It creates
missing configured tabs, restores the fixed order, and refreshes the sidebar name
for every open worktree sharing the project on that machine. Existing extra
tabs and the selected tab are preserved. Reopening a project through the picker
also refreshes its name.

The updated `dev` command takes effect when a missing dev tab is created.
A running dev tab continues until closed; reload or Alt+; then starts it with
the new command. Invalid configuration reports its file path and preserves
the existing space's last applied layout and name.

Supported roles are `nvim`, `shell`, `shell-2`, `shell-3`, `dev`, `sql`, `rest`,
`git`, `docker`, and positive numbered `oc-N` slots. `opencode` aliases `oc-1`.
Each role uses its existing launcher and the space's configured folder.

When the project has no shared definition, the picker reads
`~/.config/herdr-app/herdr-project.json` on that machine, or the same file under
`HERDR_APP_HOME`.
Chezmoi supplies this fallback:

```json
{
  "tabs": ["nvim"]
}
```

For marked projects, the fallback also applies to regular Git repositories
and non-Git folders.
The project's file takes precedence as a whole. An omitted `tabs` field or an
explicit `"tabs": []` in that file keeps a shell. Both definitions are read
afresh when opening a project.

Invalid JSON, unknown roles, duplicate roles, and invalid dev or setup fields produce an error with
the file path. A new project opens with a shell rather than a partial layout.
Herdr TUI uses its existing `herdr-project.sh` definition.

### Dev commands

Set `dev` to an executable and its arguments:

```json
{
  "tabs": ["nvim", "dev", "shell"],
  "dev": ["npm", "run", "dev"]
}
```

The command runs from the space's configured project or worktree folder.
Relative executable and argument paths resolve from that folder. Each array
entry is one argument; spaces, quotes, `$`, and `*` are passed literally.
For shell syntax or shell functions, invoke the shell explicitly:

```json
{
  "dev": ["zsh", "-ic", "npm install && npm run dev"]
}
```

Alt+; reads the current definition on the space's machine when creating a missing
`dev` tab, even if `tabs` does not include `dev`. A running tab is only focused.
Close it and use Alt+; again to launch an edited command. Invalid definitions
show their file path and leave the tab unopened so the configuration can be
corrected and retried.

The fallback file can also supply `dev`. A project file overrides the fallback
as a whole, so omitting `dev` in a project file selects the default `make dev`
behavior. Remote tabs use their own machine's paths and configuration.

### Setup hooks

Add a setup script to the project definition:

```json
{
  "tabs": ["nvim", "dev"],
  "setup": {
    "script": "herdr-setup.sh"
  }
}
```

Opening the project or choosing **Reload project config** runs setup before
creating missing configured tabs. A visible `setup` tab shows live output and
accepts input. Other spaces remain usable while it runs. Reopening a project
with setup already running focuses that terminal.

Bash runs the script from the worktree root. Relative script paths resolve
beside the JSON file. The script receives `HERDR_PROJECT_DIR`, the directory
containing that file, and `HERDR_WORKTREE_DIR`, the worktree root. A fallback
definition can also supply setup; its script resolves beside the fallback file.
Remote projects run setup on their own machine.

After a successful run, the setup tab closes and configured tabs open.
Existing tabs keep their programs. If setup fails, its output stays visible
until the tab is closed or Enter is pressed. Fix the script, then reopen the
project or reload its config to retry. Retrying replaces the managed failed
setup tab. Renamed or split tabs are preserved.

Completion is saved only after exit status zero, once per worktree and SHA-256
hash of the script's contents. Editing the script triggers setup on the next
open or reload, unless that content already succeeded for the worktree.
Only the configured script is hashed, including for remote projects.
Recreating a worktree at the same path also runs setup again. Records live under
`HERDR_APP_HOME/state/project-setup` on the worktree's machine and survive App
restarts. Concurrent launches share a worktree lock so they cannot run the same
successful hash twice.

The old `version` field is ignored. Version-based completion records require one
fresh run per worktree to save the script's hash.

### Teardown hooks

Add a teardown script to the project definition:

```json
{
  "tabs": ["nvim", "dev"],
  "teardown": {
    "script": "herdr-teardown.sh"
  }
}
```

Press Ctrl+G, then x, or open the command palette with Ctrl+Shift+P and choose
**Close project**.
In an ordinary space, this uses Herdr's normal close confirmation and never
reads project configuration. In a project, the action reads the current
definition and asks **Close project?**. If teardown is configured, the dialog
says it will run before the project closes. Cancel or Esc leaves the project
and its tabs open. Confirm runs teardown in a visible,
interactive `teardown` tab. It closes the other tabs in that space before
starting the script. Repeating the action while teardown runs focuses that tab.
Named-tab shortcuts can still create and focus tabs during teardown.

Bash runs the script from the worktree root. Relative script paths resolve
beside the JSON file. `HERDR_PROJECT_DIR` is that file's directory;
`HERDR_WORKTREE_DIR` is the worktree root. Fallback hooks resolve beside the
fallback JSON, and remote projects run teardown on their own machine.

Exit status zero closes the requested space and ends its terminals. A failed
or cancelled teardown leaves the space open; the earlier tabs have already
closed. Failure output stays visible until Enter is pressed or the tab is
closed. Fix the script and choose
**Close project** again to retry. Retrying closes the other tabs, including
the failed teardown tab, before running the script. Finish or close any running
setup tab before requesting project closure.

Teardown runs on every explicit **Close project** request, without a completion
cache. A project without a teardown hook closes after confirmation. Closing an
individual tab, using Herdr's built-in **Close space**, or quitting the window
does not run teardown. Closing a space does not remove its worktree unless
the teardown script does so.

## Space labels

The `pbogut` layout uses `mods/pbogut-spaces`, a copy of Herdr App 0.1.16's
Spaces sidebar. Ordinary spaces use Herdr's native name, which follows the
current directory unless explicitly renamed. Marked projects use the project
name from their configured folder for labels and letter tiles.
Git's common directory identifies the repository across worktrees:
`gitlab.com/assuredpharmacy/pms/.bare` gives `pms` and `P`, as does `pms/.git`.
Set `"name": "PMS"` in the shared `herdr-project.json` beside `.bare` to override
the label and its initial for marked project worktrees. Regular repositories read the file
beside `.git`; non-Git folders read it from the configured folder.
An absent, blank, or non-string `name` falls back to the repository or folder name.
Invalid JSON uses that fallback on initial load; a failed reload keeps the last name.
Folders outside Git use the folder name; a space without a folder uses its name.

The right side shows the terminal's current branch, with a leading `YYYY-MM-DD-`
removed, and ahead/behind counts. `main` and `master` are shown too. Hover over
the branch to see its full name, or over the project to see its configured folder.
These are display labels. Space names, folder paths, IDs, and Git branch names
retain their original values for pickers, named tabs, and session restoration.

Lookups are cached by machine and configured folder. Names are read when a
marked project first appears, when reopening it through the project picker, or with
**Reload project config**. Project configuration has no timer-based checks or
file watchers. After upgrading Herdr,
merge changes from the shipped Spaces mod into this copy, keeping the
configured-folder lookup, optional name, and shortened branch display.

## Space folders

The Spaces sidebar groups all spaces into `work`, `personal`, and `other` within
each machine. It uses the folding-folder design from
[Bruno-Tome/herdr-folders](https://github.com/Bruno-Tome/herdr-folders) alongside
the custom project labels above.

`folders.json` defines the folder order, fallback name, and matching rules.
Its source is encrypted at `dot_config/herdr-app/encrypted_folders.json.age`.
Keep the source encrypted when updating rules, then apply that target:

```sh
chezmoi apply ~/.config/herdr-app/folders.json
```

A relative rule such as `gitlab.com/example-work` matches that sequence of
whole directory components anywhere in a path. It works with different project
roots on remote machines. An absolute rule matches only that directory and its
descendants. These are directory paths, not Git remote URLs or glob patterns.
The longest matching rule wins; equally specific rules use the first match.

Matching uses the shared repository root resolved from the space's configured
folder. All worktrees of a `.bare` or regular Git repository follow that root,
even when a worktree lives elsewhere. Non-Git spaces use their configured folder.
Changing a terminal's directory does not change its group.
Initial folder matching and worktree nesting are independent of the project marker.

Config changes load within five seconds. Invalid edits retain the previous
configuration and show an error indicator beside Spaces. Tests use synthetic
rules in `assets/tests/herdr_app/fixtures/folders.json`; they do not decrypt the
managed configuration.

Click a folder header to fold it. The folder button beside + shows or hides empty
folders; they start hidden. Folding and the empty-folder preference survive App
restarts. Native space order follows folder order, so Alt+1…9 and previous/next
space shortcuts include collapsed spaces in that order. Switching to a hidden
space expands its folder and machine and scrolls its row into view.

Drag a space onto a folder header to assign it to that folder.
An ordinary space moves independently, even when a project uses the same directory.
A marked project moves together with its marked worktrees on that machine;
ordinary spaces in that repository stay in their own groups.
The header highlights when it can accept the drop. Use the empty-folder toggle
to reveal a destination with no spaces. Drops stay within the source machine;
dragging between space rows reorders only within their existing folder.

Manual assignments override path rules, including an explicit move to `other`.
Herdr's shared state keeps them under `pbogut.folders.assignments`.
Project assignments use machine and Git common directory, such as
`/repos/project/.bare` or `.git`. Non-Git projects use their configured directory.
Existing and future marked project worktrees inherit that assignment.
Ordinary assignments use machine, the `space` tag, and space ID.
They survive App restarts, but a newly created ordinary space uses the folder
rules again, even at the same path.

Right-click an assigned space and choose **Use matching rules** to clear its
assignment. For an ordinary space, this resets only that space. For a project,
it resets the repository's marked projects on that machine.
The menu keeps Herdr's rename,
worktree, and close actions. Its space-only implementation is in
`mods/pbogut-spaces/menu.js`, based on Herdr 0.1.16's menu.

## Agents folders and priority

The `pbogut` layout uses `mods/pbogut-agents`, based on Herdr App 0.1.16's
Agents sidebar. Open the sort menu beside Agents and choose **Folder + priority**.
The existing sort selection stays selected until you choose the new view.
Priority remains the default when no sort is saved.

Each folder contains its nonempty **Needs you**, **Done**, **Working**, and
**Idle** sections, in that order. Click a folder or section header to fold it.
Pinned agents appear above the folders. Agents on different machines share their
folder's section; remote rows show the machine name.
Sub-agent urgency can move its parent into Needs you, as in the native priority
view. Previous/next agent navigation follows the displayed order, including
agents in folded groups.

The sidebar reads resolved assignments from `pbogut.spaces.rows` and folder order
and fallback from `pbogut.spaces.folders`. Manual moves and folder configuration
changes follow Spaces. A new space uses the fallback folder until Spaces resolves it.
After a Herdr upgrade, merge changes from the shipped Agents mod into this copy.

In every sort view, agent rows show only the space's resolved project name and
branch on one line. Ordinary spaces keep their native name.
The branch uses the same date-prefix shortening as Spaces; hover over it
to see the full name. Non-Git spaces omit the branch.
Project config reloads update the labels through the shared Spaces snapshot.
Grouped-by-space headers also use the resolved name. In the narrow rail, hover
over an agent's number for its project and full branch.

## Agents picker

Alt+I opens `mods/pbogut-agents/picker.js`. It follows the Agents sidebar's
current sort, including pinned agents and agents in folded groups. Sub-agents
follow their parent; pinned sub-agents appear only once.
The first line shows the project name and shortened branch. The second shows
the computer, folder category, and full configured path, as in the Spaces picker.

Icons, status indicators, and the working spinner use the sidebar's shared
`appearance.js` renderer. Status changes update the open picker.
The current agent starts selected. Search matches project, branch, computer,
category, path, agent program, and terminal address without reordering results.
Arrow keys and Ctrl+J/K wrap at either end. Enter or a click focuses the selected
agent; Escape closes the picker. Selection follows the same agent when the
sidebar order changes.

The sidebar publishes its resolved rows under `pbogut.agents.rows`, before
folding. Closed agents are omitted. New agents remain reachable at the end
until the sidebar resolves their order.

## Spaces picker

Alt+O opens `mods/pbogut-space-picker`. It lists one row per open space in
the Spaces sidebar's machine, folder, and worktree order, including folded groups.
The current space is selected on opening. Search matches space and project names,
folders, machines, and branches without reordering results. Arrow keys and
Ctrl+J/K wrap at either end; Enter or a click switches spaces, and Escape closes.
Selecting a space restores its active tab.

The sidebar publishes its resolved rows under `pbogut.spaces.rows` in shared state.
The picker uses those labels, icons, and branch details without repeating Git
lookups. The sidebar decides the icon and color: an initial tile for a space,
or a branch icon for a nested worktree.
Closed spaces are omitted; newly created spaces appear at the end until the
sidebar resolves their order. The list scrolls to the keyboard selection.

## Customized built-in pickers

`mods/pbogut-picker` copies Herdr App 0.1.16's `mods/picker`.
`mods/pbogut-palette` copies its `frame/palette` as a regular native mod.
Ctrl+Shift+K opens the customized Go to picker; Ctrl+Shift+P opens the
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
herdr-app check dot_config/herdr-app/mods/pbogut-space-picker
herdr-app check dot_config/herdr-app/mods/pbogut-palette
herdr-app check dot_config/herdr-app/mods/pbogut-agent-status
herdr-app check dot_config/herdr-app/mods/pbogut-agents
node --experimental-vm-modules --test assets/tests/herdr_app/agents.test.mjs
node --experimental-vm-modules --test assets/tests/herdr_app/agent_picker.test.mjs
python3 -B assets/tests/herdr_app/agents.py
node --experimental-vm-modules --test assets/tests/herdr_agents/push.test.mjs
python3 -B assets/tests/herdr_agents/agents_test.py
python3 -B assets/tests/herdr_agents/push.py
herdr-app check dot_config/herdr-app/mods/pbogut-spaces
node --experimental-vm-modules --test assets/tests/herdr_app/shortcuts.test.mjs
node --test assets/tests/herdr_app/words.test.mjs
node --test assets/tests/herdr_app/send_ctrl_g.test.mjs
node --experimental-vm-modules --test assets/tests/herdr_app/named_tabs.test.mjs
node --experimental-vm-modules --test assets/tests/herdr_app/space_initials.test.mjs
node --experimental-vm-modules --test assets/tests/herdr_app/space_folders.test.mjs
node --experimental-vm-modules --test assets/tests/herdr_app/space_picker.test.mjs
python3 -B assets/tests/herdr_app/space_folders.py
node --test assets/tests/herdr_app/projects.test.mjs
node --experimental-vm-modules --test assets/tests/herdr_app/project_machines.test.mjs
node --test assets/tests/herdr_app/project_tabs.test.mjs
python3 -B assets/tests/herdr_app/setup_test.py
shellcheck dot_config/herdr-app/mods/pbogut-tabs/setup.sh
python3 -B assets/tests/herdr_app/teardown_test.py
shellcheck dot_config/herdr-app/mods/pbogut-tabs/teardown.sh
node --test assets/tests/herdr_app/worktrees.test.mjs
node --test assets/tests/herdr_app/opencode_session.test.mjs
node --test assets/tests/herdr_app/opencode_rpc.test.mjs
python3 assets/tests/herdr_app/keyboard.py
python3 assets/tests/herdr_app/prefix_input.py
python3 assets/tests/herdr_app/named_tabs.py
python3 assets/tests/herdr_app/opencode_sessions.py
python3 assets/tests/herdr_app/editor.py
python3 assets/tests/herdr_app/projects.py
python3 assets/tests/herdr_app/projects_remote.py
python3 assets/tests/herdr_app/projects.py --profile
```

The keyboard test requires Xvfb, xdotool, xclip, and Python's Pillow package with
XCB support for capturing cursor movement between frames.
It starts its own window,
home directory, and core session under `/tmp/opencode`, sends keys only there,
and stops those test processes on exit. Screenshots and logs remain in its
printed sandbox directory.
The space-folder test also checks Alt+O's sidebar order and labels, folded spaces,
search, current-space selection, Ctrl+J/K, arrow wrapping, scrolled-row clicks,
empty results, and Escape in its isolated window.
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
marked projects. It also checks that ordinary spaces are absent from the picker,
do not produce open badges, and can share a directory with a separate project.
Project markers survive a restart without converting ordinary spaces.
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
It also checks shared JSON tab definitions, real Neovim launches,
fixed order, reusing running tabs, filling missing tabs, and correcting an invalid
definition. Projects without a definition use the configurable fallback.
Custom dev checks cover literal arguments, worktree-relative paths, fallback
commands, running-tab reuse, reloading on recreation, and closing on failure.
Manual reload checks cover the command palette, fixed tab order, missing
dev tabs, and retaining the applied configuration after invalid edits.
Hook checks cover hash-based setup, interactive teardown failure and retry,
closing other tabs before teardown, named-tab shortcuts during teardown,
closing the requested space while another stays focused, and worktree removal.

The remote-picker test connects two isolated cores through a local `--via`
transport. It checks native Tab/Shift+Tab with a focused search input, machine
scoping, remote configuration and editor startup, and visible lookup failures.
It also creates a dated remote worktree through the source helpers and verifies
that the new space and its tabs stay on that machine. Setup and teardown use
that machine's fallback definition and worktree directory.

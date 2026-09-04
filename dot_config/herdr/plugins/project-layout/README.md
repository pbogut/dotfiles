# Project Layout

This plugin applies a local layout to sibling worktrees created from a bare Git
repository. Put the layout beside `.bare`, not inside a checkout:

```text
awesome-project/
  .bare/
  herdr-project.sh
  main/
  feature-one/
```

It is also the single physical plugin for managed-tab restoration, OpenCode
session caching, and repository metadata. On Herdr startup those modules run in
this order: metadata reporting, session caching, then managed-tab restoration.

The plugin does not source the layout until the canonical project directory has
been trusted through its popup or the `Trust and apply project layout` action.
Trust remains in Herdr's plugin config directory until it is revoked with the
`Revoke project layout trust` action.

Use the `Create or edit project layout` action from a worktree to create the
file from a commented template and open it in the managed nvim tab. From a
shell, run:

```bash
herdr-project-layout init
```

The command opens an existing layout without changing it.

Example `herdr-project.sh`:

```bash
HERDR_TABS=(nvim dev opencode)
HERDR_DEV_COMMAND=(make dev)
HERDR_SETUP_VERSION=1

herdr_task --progress "deployment - prod" -- make deploy TARGET=prod
herdr_task "ssh - prod" -- ssh production
herdr_task --close "refresh cache" -- make refresh-cache

herdr_setup() {
  [[ -e "$HERDR_WORKTREE_DIR/.env" ]] ||
    install -m 600 \
      "$HERDR_PROJECT_DIR/shared/.env" \
      "$HERDR_WORKTREE_DIR/.env"
}

herdr_teardown() {
  git-wt-cleanup --check "$HERDR_WORKTREE_DIR" || return
  docker compose down || return
  git-wt-cleanup --safe-only "$HERDR_WORKTREE_DIR"
}
```

`HERDR_TABS` supports the roles understood by `herdr-select-tab-or-new`. A
non-empty array is authoritative. If it is omitted or empty, the layout opens
only `nvim`. `HERDR_DEV_COMMAND` is a Bash array and runs from the worktree.
Setup runs once for each worktree and setup version. Increment
`HERDR_SETUP_VERSION` when setup needs to run again.

Selecting `nvim` focuses an existing `nvim` tab. If none exists, the selector
replaces the initial workspace tab or creates a new tab and starts Neovim once.
It does not inspect or restart an existing tab. The startup restoration hook
remains responsible for restarting commands after Herdr restores a session.

New and restarted managed command tabs start from the workspace root recorded
when its initial pane was created. Project layouts refresh that root from their
worktree path. Existing tabs are only focused, and restored shell tabs keep
their saved working directory.

Press `prefix+u` to open the project task picker. Each `herdr_task` receives a
name followed by `--` and the command arguments. Add `--progress` before the
name to animate the task tab while it runs. Add `--close` to close the tab after
either a successful or failed exit; it can be combined with `--progress`. All
task commands run from the worktree root in an attached terminal, so commands
such as `ssh` remain interactive. A task may also invoke a function declared in
the layout file.

Task tabs are singletons while they exist. Selecting a running task focuses its
tab instead of starting another command. Selecting a retained finished task
focuses its tab and asks whether to run it again. Enter replaces the completed
tab with a fresh task process, discarding its old PTY and scrollback; Escape
leaves it unchanged. Tasks with `--progress` remain open after completion and
end with `✓` or `✗` in the tab name. A task without `--progress` closes its tab
after a successful exit. If it fails, the tab remains open with `✗` so its
output can be inspected. `--close` overrides this retention behavior for both
exit outcomes.

The picker and runner source the trusted layout independently. Keep top-level
code limited to declarations and `herdr_task` registrations; put side effects
inside task, setup, or teardown functions.

Setup and teardown run in temporary Herdr tabs so long commands do not block
the rest of the UI. Setup opens missing managed tabs before showing its Done
button and reports failure if any configured tab cannot be opened. After the
countdown, successful setup closes only its own tab without changing the active
tab or workspace. Failed setup remains open until its close button is used and
does not open an editor. Closing a workspace still asks for confirmation in a
popup. After confirmation, Herdr caches the native OpenCode session and closes
the other workspace tabs before starting teardown. If teardown fails after
removing the worktree, keeping the workspace open restores Neovim in the first
surviving worktree, project, or home directory.

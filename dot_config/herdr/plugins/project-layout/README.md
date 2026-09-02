# Project Layout

This plugin applies a local layout to sibling worktrees created from a bare Git
repository. Put the layout beside `.bare`, not inside a checkout:

```text
awesome-project/
  .bare/
  .herdr-layout.sh
  main/
  feature-one/
```

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

Example `.herdr-layout.sh`:

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

`HERDR_TABS` supports the roles understood by `herdr-select-tab-or-new`.
`HERDR_DEV_COMMAND` is a Bash array and runs from the worktree. Setup runs once
for each worktree and setup version. Increment `HERDR_SETUP_VERSION` when setup
needs to run again.

Press `prefix+u` to open the project task picker. Each `herdr_task` receives a
name followed by `--` and the command arguments. Add `--progress` before the
name to animate the task tab while it runs. Add `--close` to close the tab after
either a successful or failed exit; it can be combined with `--progress`. All
task commands run from the worktree root in an attached terminal, so commands
such as `ssh` remain interactive. A task may also invoke a function declared in
the layout file.

Task tabs are singletons while they exist. Selecting a running task focuses its
tab instead of starting another command. Selecting a retained finished task
focuses its tab and asks whether to run it again; Enter reruns it in the same
pane and Escape leaves the tab unchanged. Tasks with `--progress` remain open
after completion and end with `✓` or `✗` in the tab name. A task without
`--progress` closes its tab after a successful exit. If it fails, the tab
remains open with `✗` so its output can be inspected. `--close` overrides this
retention behavior for both exit outcomes.

The picker and runner source the trusted layout independently. Keep top-level
code limited to declarations and `herdr_task` registrations; put side effects
inside task, setup, or teardown functions.

Setup and teardown run in temporary Herdr tabs so long commands do not block
the rest of the UI. Setup opens missing managed tabs before showing its Done
button. Closing a workspace still asks for confirmation in a popup. After
confirmation, Herdr closes the other workspace tabs before starting teardown.

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

Setup and teardown run in temporary Herdr tabs so long commands do not block
the rest of the UI. Setup opens missing managed tabs before showing its Done
button. Closing a workspace still asks for confirmation in a popup. After
confirmation, Herdr closes the other workspace tabs before starting teardown.

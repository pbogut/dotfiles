# Agent Instructions

## Repository Purpose

This repository is the chezmoi source directory for the user's dotfiles and
scripts. Files here are the source of truth. Chezmoi renders or copies them to
their target locations under `$HOME`.

Work inside this repository unless the user explicitly asks for changes in
another project or directory.

## Working Boundary

- Edit files in this repository, not deployed files under `~/.config`,
  `~/.scripts`, `~/.local`, or other home-directory targets.
- Do not inspect deployed files by default. Read the corresponding source file
  in this repository instead.
- Inspect a deployed target only when diagnosing a runtime/deployment problem
  or verifying that `chezmoi apply` produced the expected result.
- Never fix a deployed target directly. Fix its source here and apply it again.
- Preserve unrelated worktree changes. Other changes may belong to the user or
  another agent.

## Chezmoi Naming

Chezmoi source names encode target names and attributes. Common examples:

- `dot_config/foo/config` becomes `~/.config/foo/config`.
- `dot_scripts/tool` becomes `~/.scripts/tool`.
- `executable_tool` becomes an executable target named `tool`; do not rely on
  the source file's Unix executable bit.
- `private_name` creates a target with private permissions.
- `symlink_name` describes a symlink target.
- Files ending in `.tmpl` are rendered as Go templates; the `.tmpl` suffix is
  removed from the target name.
- Files prefixed with `encrypted_` contain encrypted managed content. Never
  replace them with plaintext or expose decrypted secrets.
- `run_once_`, `run_onchange_`, and `run_before_`/`run_after_` files are chezmoi
  scripts with lifecycle semantics. Treat changes to them as potentially
  system-wide.

Use chezmoi itself when the source-to-target mapping is unclear:

```sh
chezmoi target-path dot_config/waybar/config.tmpl
chezmoi source-path ~/.config/waybar/config
```

## Editing And Validation

1. Inspect and edit the source file in this repository.
2. Run the narrowest relevant formatter, linter, or test against the source.
3. Preview rendered content when templates are involved:

```sh
chezmoi cat ~/.config/waybar/config
```

4. Preview deployment differences for the specific target:

```sh
chezmoi diff ~/.config/waybar/config
```

5. Apply only the targets changed for the task:

```sh
chezmoi apply ~/.config/waybar/config
chezmoi apply ~/.scripts/example-tool
```

Multiple target paths may be passed to one `chezmoi apply` command. Prefer a
scoped apply over an unqualified `chezmoi apply`, because the repository may
contain unrelated unfinished changes.

After applying, verify the deployed target only when useful:

```sh
chezmoi diff ~/.config/waybar/config
```

No output means the target matches the rendered source. Runtime services may
still need an appropriate reload or restart after deployment.

## Safety

- Do not run `chezmoi update`; it pulls remote changes and applies broadly.
- Do not use `chezmoi add` for normal edits. It imports a deployed target into
  the source tree and can overwrite intentional source/template structure.
- Do not apply every managed file merely to test one change.
- Review templates and host conditionals before assuming rendered output is the
  same on every machine.
- Do not decrypt, print, commit, or otherwise expose secrets.
- Do not commit or push unless the user explicitly requests it.

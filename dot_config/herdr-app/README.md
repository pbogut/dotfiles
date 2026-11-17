# Herdr App configuration

Chezmoi manages these files. The `pbogut` layout uses bottom tabs and borderless,
gapless panes. Terminal text matches Alacritty's 12 pt at 16 px.

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

Alt+Esc opens copy mode directly. It uses the app's terminal selection.
Move with `hjkl` or arrows,
start or stop selection with `v` or Space, and select lines with `V`.
`0` and `$` move to line edges. `gg` and `G` move to the history edges.
Page Up / Ctrl+B and Page Down / Ctrl+F move a page.
`y` or Enter copies and exits. Escape or `q` cancels. Exiting clears the
selection and returns to the live screen.

The named-tab shortcuts and project-plugin bindings still need their helper
port. They are not installed in this increment.

## Checks

Run from the chezmoi source directory:

```sh
herdr-app check dot_config/herdr-app/mods/pbogut-keys
herdr-app check dot_config/herdr-app/mods/pbogut-copy
node --experimental-vm-modules --test assets/tests/herdr_app/shortcuts.test.mjs
python3 assets/tests/herdr_app/keyboard.py
```

The keyboard test requires Xvfb, xdotool, and xclip. It starts its own window,
home directory, and core session under `/tmp/opencode`, sends keys only there,
and stops those test processes on exit. Screenshots and logs remain in its
printed sandbox directory.

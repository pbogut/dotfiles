#!/bin/bash
cwd=$(xcwd)

for arg in "$@"; do
    case $arg in
        "--new-workspace" )
            i3-create-empty-workspace.py
    esac
done

cd "$cwd"

if which "$TERMINAL"; then
  $TERMINAL || xterm
elif which alacritty; then
  alacritty
elif which urxvt; then
  urxvt
else
  xterm
fi

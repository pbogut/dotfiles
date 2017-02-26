#!/bin/bash
cwd=$(xcwd)

for arg in "$@"; do
    case $arg in
        "--new-workspace" )
            i3-create-empty-workspace.py
    esac
done

urxvt -cd "$cwd"

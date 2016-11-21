#!/bin/bash
current=$(i3-msg -t get_workspaces | jq -r '.[].name')
static=$(cat ~/.config/i3/workspaces | sed 's/\(.*\)/0:\1/')
echo -e "$current\n$static" \
    | sort \
    | sed 's/^[0-9]*://' \
    | rofi -dmenu \
    | sed 's/\(.*\)/0:\1/' \
    | sed 's/0:\([0-9]*\)$/\1/' \
    | xargs i3-msg workspace


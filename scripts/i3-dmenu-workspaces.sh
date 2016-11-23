#!/bin/bash
current=$(i3-msg -t get_workspaces | jq -r '.[].name')
static=$(cat ~/.config/i3/workspaces | sed 's/\(.*\)/0:\1/')
if [[ $1 == '--move' ]];then
    label="move:"
elif [[ $1 == '--send' ]]; then
    label="send:"
else
    label="switch:"
fi
echo -e "$current\n$static" \
    | sort \
    | uniq \
    | sed 's/^[0-9]*://' \
    | rofi -dmenu -i -l 20 -p $label \
    | sed 's/\(.*\)/0:\1/' \
    | sed 's/0:\([0-9]*\)$/\1/' \
    | while read ws; do

if [[ -n $ws ]]; then
    if [[ $1 == "--move" || $1 == "--send" ]];then
        i3-msg "move --no-auto-back-and-forth workspace $ws"
    fi
    if [[ $1 == "--move" || $1 == "" ]];then
        i3-msg "workspace --no-auto-back-and-forth $ws"
    fi
fi
done


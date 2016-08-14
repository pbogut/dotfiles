#!/bin/bash
id=$(xprop -root | awk '/_NET_ACTIVE_WINDOW\(WINDOW\)/{print $NF}')
name=$(xprop -id $id | awk '/_NET_WM_NAME/{$1=$2="";print}' | cut -d'"' -f2)
workspaces=$(~/.scripts/i3-show-workspaces.py)
if [ -z "$name" ]; then
    name="Desktop"
fi
if [ "$1" == "--container" ]; then
    echo -e "$2 $name $3"
else
    echo -e "$name"
fi

#!/bin/bash
i3status --config ~/.config/i3/i3status.conf | while :
do
    read line
    id=$(xprop -root | awk '/_NET_ACTIVE_WINDOW\(WINDOW\)/{print $NF}')
    name=$(xprop -id $id | awk '/_NET_WM_NAME/{$1=$2="";print}' | cut -d'"' -f2)
    workspaces=$(~/.scripts/i3-show-workspaces.py)
    if [ -z $name ];then
        name="Desktop"
    fi
    echo -e "&#xf24d; [$name]   &#xf053;      $workspaces   &#xf053;      $line" || exit 1
done

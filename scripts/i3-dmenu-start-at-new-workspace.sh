#!/bin/bash
commands=`compgen -c | tail -n+26`
zsh_aliases=`zsh -ic alias | sed 's/^\([^=]*\)=.*/\1/g'`
echo "$zsh_aliases"
echo "$commands\n$zsh_aliases" | sort | uniq | rofi -dmenu -i -l 20 -p 'new ws:' | while read cmd; do
    ~/.scripts/i3-create-empty-workspace.py && $cmd
done


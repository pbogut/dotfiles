#!/bin/bash
commands=`compgen -c | tail -n+26`
zsh_aliases=`zsh -ic alias | sed 's/^\([^=]*\)=.*/\1/g'`
echo "$zsh_aliases"
echo "$commands\n$zsh_aliases" | sort | uniq | dmenu -l 20 -p term | while read cmd; do
    roxterm --separate -e zsh -ic "$cmd"
done


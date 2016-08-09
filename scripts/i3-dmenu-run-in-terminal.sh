#!/bin/bash
compgen -c | tail -n+26 \
    | dmenu -l 20 -p term | while read cmd; do
    roxterm --separate -e zsh -i -c "$cmd"
done


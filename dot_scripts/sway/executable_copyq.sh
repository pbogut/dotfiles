#!/bin/zsh
row=$(copyq 'dmenuList()' \
    | sed 's/!newline!/󰌑 /g' \
    | cut -c 1-256 \
    | fuzzel --dmenu -p 'copyq: ' --cache /dev/null \
    | sed 's,\([0-9]*\).*,\1,')

if [[ "$row" != "" ]]; then
    copyq select $row
fi

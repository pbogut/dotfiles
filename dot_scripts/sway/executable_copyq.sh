#!/bin/zsh
row=$(copyq 'dmenuList()' \
    | sed 's/!newline!/󰌑 /g' \
    | wofi --dmenu -i -l 20 -p 'copyq:' --cache-file /dev/null \
    | sed 's,\([0-9]*\).*,\1,')

if [[ "$row" != "" ]]; then
    copyq select $row
fi

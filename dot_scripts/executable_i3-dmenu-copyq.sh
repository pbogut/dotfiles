#!/bin/zsh
# display clipboard text
row=$(copyq-list.sh \
    | rofi -dmenu -i -l 20 -p 'copyq:' \
    | sed 's,\([0-9]*\).*,\1,')

if [[ "$row" != "" ]]; then
    copyq select $row
fi

#!/bin/zsh
# display clipboard text
anamnesis.sh list \
    | rofi -dmenu -i -l 20 -p 'clipboard:' \
    | anamnesis.sh to_clip

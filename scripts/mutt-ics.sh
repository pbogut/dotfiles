#!/bin/bash
#=================================================
# name:   mutt-ics.sh
# author: Pawel Bogut <https://pbogut.me>
# date:   21/12/2018
#=================================================
~/.scripts/icalview.rb $1 | head -n2
echo "----------"
khal printics $1
if [[ -n $DISPLAY ]]; then
    selection=$(echo -e "show\nimport" | rofi -dmenu)
    if [[ $selection == "import" ]]; then
        urxvt -title "FLOATING_WINDOW" -e khal import $1
    fi
fi

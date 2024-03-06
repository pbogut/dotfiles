#!/bin/bash
#=================================================
# name:   mutt-ics.sh
# author: Pawel Bogut <https://pbogut.me>
# date:   21/12/2018
#=================================================
clear
format="
Title:    {cancelled}{title} {repeat-symbol}
Date:     {start-long} - {end-long}
Location: {location}

{description}"

khal printics -f "$format" $1 | tail -n+3

if [[ $2 == "int" ]]; then
    echo -en "\n\n>> Do you want to import this event to your calendar? (y/[n]): "
    read ans
    if [[ $ans == "y" || $ans == "Y" ]]; then
        echo -e "\n\n\n"
        khal import $1
    fi
fi

# if [[ -n $DISPLAY ]]; then
#     selection=$(echo -e "show\nimport" | rofi -dmenu)
#     if [[ $selection == "import" ]]; then
#         urxvt -title "FLOATING_WINDOW" -e khal import $1
#     fi
# fi

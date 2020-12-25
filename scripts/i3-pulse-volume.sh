#!/bin/bash
#=================================================
# name:   i3-pulse-volume.sh
# author: Pawel Bogut <https://pbogut.me>
# date:   17/10/2019
#=================================================

if [[ $1 == "1" ]]; then
    vol=$(pulsemixer --get-volume | awk '{ print $1 }' | sed 's,\(.*\),\1,')
    if [[ "$vol" == "0" ]]; then
        pulsemixer --set-volume 100
        echo "100%"
    else
        pulsemixer --set-volume 0
        echo "0%"
    fi
elif [[ $1 == "2" ]]; then
    ~/.scripts/audio-device-switch.sh
    pulsemixer --get-volume | awk '{ print $1 }' | sed 's,\(.*\),\1%,'
elif [[ $1 == "3" ]]; then
    echo "DISPLAY=:0.0 pavucontrol -t 1" | at now
    pulsemixer --get-volume | awk '{ print $1 }' | sed 's,\(.*\),\1%,'
elif [[ $1 == "4" ]]; then
    pulsemixer --change-volume +5
    pulsemixer --get-volume | awk '{ print $1 }' | sed 's,\(.*\),\1%,'
elif [[ $1 == "5" ]]; then
    pulsemixer --change-volume -5
    pulsemixer --get-volume | awk '{ print $1 }' | sed 's,\(.*\),\1%,'
else
    echo "$1$(
    sleep 0.1s; pulsemixer --get-volume | awk '{ print $1 }' | sed 's,\(.*\),\1%,')"
fi

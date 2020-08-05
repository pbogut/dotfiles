#!/bin/bash
#=================================================
# name:   i3-pulse-volume.sh
# author: Pawel Bogut <https://pbogut.me>
# date:   17/10/2019
#=================================================

if [[ $1 == "1" ]]; then
    pulsemixer --change-volume +1
    pulsemixer --get-volume | awk '{ print $1 }' | sed 's,\(.*\),\1%,'
elif [[ $1 == "2" ]]; then
    ~/.scripts/audio-device-switch.sh
    pulsemixer --get-volume | awk '{ print $1 }' | sed 's,\(.*\),\1%,'
elif [[ $1 == "3" ]]; then
    pulsemixer --change-volume -1
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

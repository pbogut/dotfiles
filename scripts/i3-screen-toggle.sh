#!/bin/bash
#=================================================
# name:   i3-screen-toggle.sh
# author: Pawel Bogut <https://pbogut.me>
# date:   26/08/2019
#=================================================
screens=$(xrandr --listactivemonitors | grep "^ " | wc -l)
button=$1


if [[ $button -eq 1 ]] && [[ $screens -eq 1 ]]; then
    screens=2
    ~/.screenlayout/2-monitors.sh
elif [[ $button -eq 1 ]] && [[ $screens -eq 2 ]]; then
    screens=1
    ~/.screenlayout/1-monitor.sh
fi
if [[ $screens -eq 1 ]]; then
    echo 
elif [[ $screens -eq 2 ]]; then
    echo 
fi

#!/bin/bash
#=================================================
# name:   i3-screen-saver-toggle.sh
# author: Pawel Bogut <https://pbogut.me>
# date:   16/02/2020
#=================================================
scrsave="$(xset q | grep 'timeout:  0')"
button=$1

state="on"
if [[ "$(ps -e | grep barriers)" == "" ]]; then
    state="off"
fi

if [[ $button != "" ]] && [[ $state == "on" ]]; then
    sudo killall barriers -9
    state="off"
elif [[ $button != "" ]] && [[ $state == "off" ]]; then
    barriers
    state="on"
fi

if [[ $state == "on" ]]; then
    echo 
else
    echo 
fi



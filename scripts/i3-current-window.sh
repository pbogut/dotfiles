#!/bin/bash
#=================================================
# name:   i3-current-window.sh
# author: Pawel Bogut <pbogut@ukpos.com> <http://pbogut.me>
# date:   26/01/2017
#=================================================
win=`xdotool getwindowfocus`
eval `xdotool getwindowgeometry --shell $win`

posx=`expr $WIDTH / 2 + $X`
posy=`expr $HEIGHT / 2 + $Y`
xdotool mousemove $posx $posy


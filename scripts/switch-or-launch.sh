#!/bin/bash
#=================================================
# name:   switch-or-launch.sh
# author: Pawel Bogut <http://pbogut.me>
# date:   15/07/2017
#=================================================
id=$(xdotool getwindowfocus)
win=$(xprop -id $id |grep '^WM_NAME' | sed 's/[^=]* = "\(.*\)"$/\1/' | grep "$1")
if [[ -n $win && -n $id ]]; then
  i3-msg workspace back_and_forth
else
  win=$(wmctrl -l | grep "$1" | awk '{print $1}')
  if [[ -n $win ]]; then
    wmctrl -ia $win
  else
    $2 &
  fi
fi

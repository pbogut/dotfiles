#!/bin/bash
#=================================================
# name:   switch-or-launch.sh
# author: Pawel Bogut <http://pbogut.me>
# date:   15/07/2017
#=================================================
last_id_file="/tmp/$USER/_switch-or-launch.last_id"
mkdir -p $(dirname $last_id_file)
touch $last_id_file

last_id=$(cat $last_id_file)
id=$(xdotool getwindowfocus)

echo $id > $last_id_file

win=$(xprop -id $id |grep '^WM_NAME' | sed 's/[^=]* = "\(.*\)"$/\1/' | grep "$1")
if [[ -n $win && -n $id ]]; then
  wmctrl -ia $last_id
else
  win=$(wmctrl -l | grep "$1" | awk '{print $1}')
  if [[ -n $win ]]; then
    wmctrl -ia $win
  else
    $2 &
    # wait for app to be open
    for i in {1..20}; do
      sleep 0.1s
      if [[ -n $(wmctrl -l | grep "$1" | awk '{print $1}') ]]; then
        break
      fi
    done
    wmctrl -ia $(wmctrl -l | grep "$1" | awk '{print $1}')
  fi
fi

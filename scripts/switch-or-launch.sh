#!/bin/bash
#=================================================
# name:   switch-or-launch.sh
# author: Pawel Bogut <http://pbogut.me>
# date:   15/07/2017
#=================================================
last_id_file="/tmp/$USER/_switch-or-launch.last_id"
workspc_file="/tmp/$USER/_switch-or-launch.workspc"
mkdir -p $(dirname $last_id_file)
touch $last_id_file
touch $workspc_file

last_id=$(cat $last_id_file)
id=$(xdotool getwindowfocus)

echo $id > $last_id_file

win=$(( $(wmctrl -lx | grep "$1" | awk '{print $1}' | head -n1) ))

if [[ -n $id && "$win" == "$id" ]]; then
  cat $workspc_file | while read workspc_id; do
    i3-msg -t command  workspace $workspc_id
  done
  sleep 0.15s;
  wmctrl -ia $last_id
else
  i3-msg -t get_workspaces | jq '.[] | select(.visible==true).name' | cut -d"\"" -f2  $workspc_file

  win=$(wmctrl -lx | grep "$1" | awk '{print $1}' | head -n1)
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

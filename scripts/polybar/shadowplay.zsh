#!/bin/env zsh
#=================================================
# name:   shadowplay.sh
# author: Pawel Bogut <https://pbogut.me>
# date:   24/03/2022
#=================================================
cycle=0    #init cycle
tick=1   #tick every n secnds
refresh=10 #refresh every n seconds

main_action() {
  win_id=$(ps -ef | grep -v grep | grep gpu-screen-recorder | sed -E 's/.*-w ([0-9]+) -s.*/\1/')

  if [[ ! -z $win_id ]]; then
    title=$(xdotool getwindowname $win_id)

    if [[ -z $title ]]; then
      echo "REC"
    else
      echo "REC ($title)"
    fi
  else
    echo ''
  fi
}

main_action

while true; do
  if [[ $cycle -ge $((refresh / tick)) ]]; then
    main_action
    cycle=0
  fi
  cycle=$((cycle + 1))
  sleep ${tick}s
done

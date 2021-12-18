#!/bin/env zsh
#=================================================
# name:   check-updates.sh
# author: Pawel Bogut <https://pbogut.me>
# date:   23/11/2021
#=================================================
cycle=0           #init cycle
tick=0.2          #tick every n secnds
refresh=7200      #refresh every n seconds

main_action() {
  count=$(checkupdates | wc -l)

  if [[ $count -gt 100 ]]; then
    echo "%{u#bd2c40}%{+u}$count%{-u}"
  elif [[ $count -gt 50 ]]; then
    echo "%{u#bdbd40}%{+u}$count%{-u}"
  elif [[ $count -gt 0 ]]; then
    echo $count
  else
    echo ""
  fi
}

trap "main_action" USR1

main_action

while true; do
  if [[ $cycle -ge $((refresh / tick)) ]]; then
    main_action
    cycle=0
  fi
  cycle=$((cycle + 1))
  sleep ${tick}s
  wait
done

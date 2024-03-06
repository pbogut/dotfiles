#!/bin/env zsh
#=================================================
# name:   check-updates.sh
# author: Pawel Bogut <https://pbogut.me>
# date:   23/11/2021
#=================================================
cycle=0           #init cycle
tick=0.2          #tick every n secnds
refresh=7200      #refresh every n seconds
count=0

main_action() {
  count=$(checkupdates | wc -l)

  if [[ $count -gt 500 ]]; then
    echo "%{u#bd2c40}%{+u}%{F#2e9ef4}%{F-}%{u-}"
  elif [[ $count -gt 100 ]]; then
    echo "%{u#2e9ef4}%{+u}%{F#2e9ef4}%{F-}%{u-}"
  else
    echo ""
  fi
}

notify() {
  main_action

  notify-send -i /usr/share/icons/gnome/32x32/apps/system-software-install.png \
    "There are $count packages ready for update." > /dev/null 2>&1
}

trap "notify" USR1

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

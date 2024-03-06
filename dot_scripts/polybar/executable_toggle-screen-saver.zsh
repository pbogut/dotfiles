#!/bin/env zsh
#=================================================
# name:   toggle-screen-saver.zsh
# author: Pawel Bogut <https://pbogut.me>
# date:   21/12/2020
#=================================================
cycle=0    #init cycle
tick=0.2   #tick every n secnds
refresh=30 #refresh every n seconds

state="off"

update_state() {
  scrsave="$(xset q | grep 'timeout:  0')"
  if [[ $scrsave == "" ]]; then
    state="on"
  fi
}

change_state() {
  update_state
  if [[ $state == "on" ]]; then
    xset s off -dpms
    state="off"
  else
    xset s on +dpms
    state="on"
  fi
  show_state
}

show_state() {
  if [[ $state == "on" ]]; then
    echo 
  else
    echo 
  fi
}

trap "change_state" USR1

update_state
show_state

while true; do
  if [[ $cycle -ge $((refresh / tick)) ]]; then
    update_state
    show_state
    cycle=0
  fi
  cycle=$((cycle + 1))
  sleep ${tick}s
  wait
done

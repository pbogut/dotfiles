#!/bin/env zsh
#=================================================
# name:   toggle-barrier.zsh
# author: Pawel Bogut <https://pbogut.me>
# date:   21/12/2020
#=================================================
cycle=0   #init cycle
tick=0.2   #tick every n secnds
refresh=30 #refresh every n seconds

state="off"

switch_state() {
  update_state
  if [[ $state == "on" ]]; then
    killall barriers -9
    state="off"
  else
    barriers --disable-crypto
    state="on"
  fi
  show_state
}

update_state() {
  state="off"
  if [[ "$(ps -e | grep barriers)" != "" ]]; then
    state="on"
  fi
}

show_state() {
  if [[ $state == "on" ]]; then
    echo 
  else
    echo 
  fi
}

trap "switch_state" USR1

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

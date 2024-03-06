#!/bin/env zsh
#=================================================
# name:   openhab-toggle-switch.zsh
# author: Pawel Bogut <https://pbogut.me>
# date:   21/12/2020
#=================================================
cycle=0    #init cycle
tick=0.2   #tick every n secnds
refresh=30 #refresh every n seconds

item="$1"

state="OFF"

update_state() { # $1 - item
  state=$(curl -X GET --header "Accept: application/json" \
    "http://openhab.local:8080/rest/items/$1" 2>/dev/null |
    jq .state -r)
}

set_state() { # $1 - item, $2 - state
  curl -X POST --header "Content-Type: text/plain" --header "Accept: application/json" -d "$2" \
    "Http://openhab.local:8080/rest/items/$1" 2>/dev/null
}


switch_state() {
  update_state $item
  if [[ $state == "ON" ]]; then
    state="OFF"
  else
    state="ON"
  fi
  set_state $item $state
  show_state
}

show_state() {
  if [[ $state == "ON" ]]; then
    echo 
  else
    echo 
  fi
}

trap "switch_state" USR1

update_state $item
show_state

while true; do
  if [[ $cycle -ge $((refresh / tick)) ]]; then
    update_state $item
    show_state
    cycle=0
  fi
  cycle=$((cycle + 1))
  sleep ${tick}s
  wait
done

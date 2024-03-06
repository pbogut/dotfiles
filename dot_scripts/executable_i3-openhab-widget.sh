#!/bin/bash
#=================================================
# name:   i3-openhab-widget.sh
# author: Pawel Bogut <https://pbogut.me>
# date:   24/08/2020
#=================================================
get_state() {
  curl -X GET --header "Accept: application/json" \
    "http://openhab.local:8080/rest/items/$1" 2>/dev/null |
    jq .state -r
}

set_state() { # $1 - item, $2 - state
  curl -X POST --header "Content-Type: text/plain" --header "Accept: application/json" -d "$2" \
    "Http://openhab.local:8080/rest/items/$1" 2>/dev/null
}

toggle_on_off() { # $1 - item
  state=$(get_state $1)
  if [[ $state == "ON" ]]; then
    set_state $1 OFF
    echo "OFF"
  elif [[ $state == "OFF" ]]; then
    set_state $1 ON
    echo "ON"
  fi
}

type="$1"
item="$2"
button="$3"

if [[ $type == "SWITCH_TOGGLE" ]]; then
  state=$([[ "$button" != "" ]] && toggle_on_off $item || get_state $item)
  if [[ $state == "ON" ]]; then
    echo 
  elif [[ $state == "OFF" ]]; then
    echo 
  fi
fi

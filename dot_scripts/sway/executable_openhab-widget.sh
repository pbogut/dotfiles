#!/usr/bin/env bash
#=================================================
# name:   openhab-widget
# author: author <author_contact>
# date:   13/07/2023
#=================================================
item="$2"
action="$1"
state="OFF"

update_state() { # $1 - item
  state=$(curl --connect-timeout 1 -X GET --header "Accept: application/json" \
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

if [[ $action == "show" ]]; then
  update_state "$item"
  show_state
  exit 0
fi

if [[ $action == "toggle" ]]; then
  switch_state
  exit 0
fi

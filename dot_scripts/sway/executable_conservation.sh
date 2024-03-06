#!/usr/bin/env bash
#=================================================
# name:   conservation
# author: author <author_contact>
# date:   13/07/2023
#=================================================
action="$1"

toggle() {
  if [[ "$state" == "on" ]]; then
    sudo ideapad-cm disable
    state="off"
  else
    sudo ideapad-cm enable
    state="on"
  fi
  # update_state
  show_state
}

update_state() {
  if [[ "$(ideapad-cm status)" =~ enabled ]]; then
    state="on"
  else
    state="off"
  fi
}

show_state() {
  if [[ $state == "on" ]]; then
		echo 
	else
		echo 
  fi
}

update_state
if [[ $action == "toggle" ]]; then
  toggle
  exit 0
else
  show_state
  exit 0
fi

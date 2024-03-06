#!/bin/bash
#=================================================
# name:   conservation-mode.sh
# author: Pawel Bogut <https://pbogut.me>
# date:   27/05/2021
#=================================================
cycle=0    #init cycle
slp=0.2    #sleep for tick (tick / 1000)
tick=200   #tick every n miliseconds
refresh=5  #refresh every n seconds
refresh=$((refresh * 1000)) #convert to mili seconds

state=""

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

trap "toggle" SIGRTMIN+1

update_state
show_state

while true; do
  if [[ $cycle -ge $((refresh / tick)) ]]; then
    update_state
    show_state
    cycle=0
  fi
  cycle=$((cycle + 1))
  sleep ${slp}s
  wait
done

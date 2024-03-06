#!/bin/env bash
#=================================================
# name:   xcape-toggle.sh
# author: Pawel Bogut <https://pbogut.me>
# date:   22/05/2021
#=================================================
cycle=0                     #init cycle
slp=0.2                     #sleep for tick (tick / 1000)
tick=200                    #tick every n miliseconds
refresh=5                   #refresh every n seconds
refresh=$((refresh * 1000)) #convert to mili seconds

state="off"
xcape=$(ps -ef | grep "xcape -e" | grep -v 'grep' | grep -v 'bash')
if [[ "$xcape" == "" ]]; then
  state="off"
else
  state="on"
fi

toggle() {
  if [[ "$state" == "on" ]]; then
    state="off"
    killall xcape -9
  else
    state="on"
    setxkbmap -option 'caps:ctrl_modifier'
    xcape -e 'Control_L=Escape'
    xcape -e 'Shift_L=parenleft'
    xcape -e 'Shift_R=parenright'
  fi
  # update_state
  show_state
}

update_state() {
  xcape=$(ps -ef | grep "xcape -e" | grep -v 'grep' | grep -v 'bash')
  if [[ "$xcape" == "" ]]; then
    state="off"
  else
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

trap "toggle" SIGRTMIN+1

# update_state
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

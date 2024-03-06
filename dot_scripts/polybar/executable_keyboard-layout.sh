#!/bin/env bash
#=================================================
# name:   keyboard-layout.sh
# author: Pawel Bogut <https://pbogut.me>
# date:   21/05/2021
#=================================================
cycle=0    #init cycle
slp=0.2    #sleep for tick (tick / 1000)
tick=200   #tick every n miliseconds
refresh=5  #refresh every n seconds
refresh=$((refresh * 1000)) #convert to mili seconds

variant=""
eval $(setxkbmap -query | sed 's#\<\([^\>]*\):.*\<\(.*\)\>#\1="\2"#' | grep -v options)

toggle() {
  if [[ $variant == "colemak" ]]; then
    setxkbmap pl
    variant=""
  else
    setxkbmap pl -variant colemak
    variant="colemak"
  fi
  # update_state
  show_state
}

update_state() {
  eval $(setxkbmap -query | sed 's#\<\([^\>]*\):.*\<\(.*\)\>#\1="\2"#' | grep -v options)
}

show_state() {
  if [[ $variant == "colemak" ]]; then
    echo "cmk"
  else
    echo "pol"
  fi
}

trap "toggle" SIGRTMIN+1

# update_state
show_state

while true; do
  if [[ $cycle -ge $((refresh / tick)) ]]; then
    # update_state
    show_state
    cycle=0
  fi
  cycle=$((cycle + 1))
  sleep ${slp}s
  wait
done

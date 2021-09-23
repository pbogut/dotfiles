#!/bin/env bash
#=================================================
# name:   pulseaudio-volume.sh
# author: Pawel Bogut <https://pbogut.me>
# date:   22/12/2020
#=================================================
refresh=5  #refresh every n seconds
refresh=$((refresh * 1000)) #convert to mili seconds

last_state="100"
state="100"

volume_up() {
  pulsemixer --change-volume +5
  update_state
  show_state
}

volume_down() {
  pulsemixer --change-volume -5
  update_state
  show_state
}

volume_mute() {
  update_state
  if [[ $state == "0" ]]; then
    pulsemixer --set-volume $last_state
    state=$last_state
  else
    last_state=$state
    pulsemixer --set-volume 0
    state="0"
  fi
  show_state
}

update_state() {
  state=$(pulsemixer --get-volume | awk '{ print $1 }' | sed 's,\(.*\),\1,')
}

show_state() {
  echo ${state}%
}

trap "volume_up"   SIGRTMIN+1
trap "volume_down" SIGRTMIN+2
trap "volume_mute" SIGRTMIN+3

update_state
show_state

#watch changes in real time
pactl subscribe | grep --line-buffered "sink" | while read x; do
  update_state
  show_state
done

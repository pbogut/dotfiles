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

name=$1
id=$(pulsemixer --list-sinks | grep "$name" | awk '{print $3}' | sed 's/,//')

if [[ -z $name ]]; then
  id=""
else
  name="Name: $name"
  id="--id $id"
fi

update_state() {
  id=$(pulsemixer --list-sinks | grep "$name" | awk '{print $3}' | sed 's/,//')
  state=$(pulsemixer --get-volume --id $id | awk '{ print $1 }' | sed 's,\(.*\),\1,')
}

show_state() {
  echo ${state}%
}

update_state
show_state

#watch changes in real time
pactl subscribe | grep --line-buffered "sink" | while read x; do
  update_state
  show_state
done

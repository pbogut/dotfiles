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

fifo="$TMPDIR/_pavol_$(md5sum <<< "$name" | awk '{print $1}')"
touch "$fifo" > /dev/null 2>&1
(tail -f "$fifo" 2>/dev/null | xob -q -s "$(hostname)") &
(tail -f "$fifo" 2>/dev/null | osd_cat -p top -i 1100 -o 30 -l 1 -d 1 -f "-misc-dejavu sans-*-*-*-*-*-*-*-*-*-*-*-*" -c "#285577" -O 2) &

id=$(pulsemixer --list-sinks | grep "$name" | awk '{print $3}' | sed 's/,//')

update_state() {
  truncate --size=0 "$fifo"
  id=$(pulsemixer --list-sinks | grep "$name" | awk '{print $3}' | sed 's/,//')
  state=$(pulsemixer --get-volume --id "$id" | awk '{ print $1 }' | sed 's,\(.*\),\1,')
}

show_state() {
  echo "${state}%"
  echo "${state}" >> "$fifo"
}

update_state
show_state

#watch changes in real time
pactl subscribe | grep --line-buffered "sink" | while read -r _; do
  last_state="$state"
  update_state
  if [[ $last_state -ne $state ]]; then
    show_state
  fi
done

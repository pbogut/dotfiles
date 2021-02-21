#!/bin/bash

default_sink=$(pactl info | grep '^Default Sink' | sed 's,Default Sink: ,,')
default_sink=$(pactl list short sinks | grep $default_sink | awk '{print $1}')

first_sink_index=$(pactl list short sinks |
  awk '{print $1}' |
  head -n1)

next_sink_index=$(pactl list short sinks |
  awk '{print $1}' |
  sed '0,/^'$default_sink'$/d' |
  head -n1)

if [[ "$next_sink_index" == "" ]]; then
  next_sink_index=$first_sink_index
fi

#change the default sink
pactl set-default-sink $next_sink_index

#move all inputs to the new sink
for app in $(pactl list short sink-inputs | awk '{print $1}'); do
  pactl move-sink-input $app $next_sink_index
done

new_sink=$(pactl info | grep '^Default Sink' | sed 's,Default Sink: ,,')
#display notification
pactl list sinks |
  sed '/'$new_sink'/I,$!d' |
  sed -n -e 's/device.description[[:space:]]=[[:space:]]"\(.*\)"/\1/p' |
  while read line; do
    notify-send -i audio-volume-high "Sound output switched to" "$line"
    exit
  done

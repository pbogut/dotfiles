#!/bin/bash
default_sink=$(pactl info | grep '^Default Source' | sed 's,Default Source: ,,')
default_sink=$(pactl list short sources | grep $default_sink | awk '{print $1}')

first_sink_index=$(pactl list short sources |
  grep -v '\.monitor\>' |
  awk '{print $1}' |
  head -n1)

next_sink_index=$(pactl list short sources |
  grep -v '\.monitor\>' |
  awk '{print $1}' |
  sed '0,/^'$default_sink'$/d' |
  head -n1)

if [[ "$next_sink_index" == "" ]]; then
  next_sink_index=$first_sink_index
fi

#change the default sink
pactl set-default-source $next_sink_index

#move all inputs to the new sink
for app in $(pactl list short source-outputs | awk '{print $1}'); do
  pactl move-source-output $app $next_sink_index
done

new_sink=$(pactl info | grep '^Default Source' | sed 's,Default Source: ,,')
#display notification
pactl list sources |
  sed '/'$new_sink'/I,$!d' |
  sed -n -e 's/device.description[[:space:]]=[[:space:]]"\(.*\)"/\1/p' |
  while read line; do
    notify-send -i microphone-sensitivity-high  "Sound input switched to" "$line"
    exit
  done

#!/bin/bash
first_sink_index=$(pacmd list-sinks |
  grep 'index:[[:space:]][[:digit:]]' |
  sed 's/.*index:[[:space:]]\([[:digit:]]\)/\1/' |
  head -n1)
next_sink_index=$(pacmd list-sinks |
  grep 'index:[[:space:]][[:digit:]]' |
  sed '/\*[[:space:]]index:[[:space:]][[:digit:]]/I,$!d' |
  sed 's/.*index:[[:space:]]\([[:digit:]]\)/\1/' |
  tail -n+2)

if [[ "$next_sink_index" == "" ]]; then
  next_sink_index=$first_sink_index
fi

#change the default sink
pacmd "set-default-sink ${next_sink_index}"

#move all inputs to the new sink
for app in $(pacmd list-sink-inputs | sed -n -e 's/index:[[:space:]]\([[:digit:]]\)/\1/p'); do
  pacmd "move-sink-input $app $next_sink_index"
done

#display notification
pacmd list-sinks |
  sed '/\*[[:space:]]index:[[:space:]][[:digit:]]/I,$!d' |
  sed -n -e 's/device.description[[:space:]]=[[:space:]]"\(.*\)"/\1/p' |
  while read line; do
    notify-send -i audio-volume-high "Sound output switched to" "$line"
    exit
  done

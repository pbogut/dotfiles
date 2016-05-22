#!/bin/bash

declare -i sinks_count=`pacmd list-sinks | grep -c index:[[:space:]][[:digit:]]`
declare -i active_sink_index=`pacmd list-sinks | sed -n -e 's/\*[[:space:]]index:[[:space:]]\([[:digit:]]\)/\1/p'`
declare -i major_sink_index=$sinks_count-1
declare -i next_sink_index=0

if [ "$1" == "up" ] ; then
	pactl set-sink-volume $active_sink_index +5%
fi

if [ "$1" == "down" ] ; then
	pactl set-sink-volume $active_sink_index -5%
fi

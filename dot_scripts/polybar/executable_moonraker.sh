#!/usr/bin/env bash
#=================================================
# name:   moonraker
# author: author <author_contact>
# date:   05/01/2023
#=================================================

address="$1"

state=$(curl -s "$address/printer/objects/query?idle_timeout" | jq -r '.result.status.idle_timeout.state')
progress=0

printer_state=$(curl -s "$address/printer/info" | jq -r '.result.state')
# state = Idle / Printing / Ready
if [[ $state == "Printing" ]]; then
    progress=$(curl -s "$address/printer/objects/query?virtual_sdcard" | jq '.result.status.virtual_sdcard.progress')
    progress=$(calc "$progress * 100" | sed 's/[^0-9]*\([0-9]*\)\..*/\1/')
    echo "$state ($progress%)"
elif [[ $state == "Idle" ]] && [[ $printer_state == 'shutdown' ]]; then
    echo "Off"
else
    echo "$state"
fi

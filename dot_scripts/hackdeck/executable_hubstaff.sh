#!/usr/bin/env bash
#=================================================
# name:   hubstaff
# author: Pawel Bogut <pbogut@pbogut.me>
# date:   07/02/2025
#=================================================
if [[ $1 == "toggle" ]]; then
    json=$(hubstaff toggle)
    error=$(jq -r .error <<< "$json")
    if [[ $error != "null" ]]; then
        hubstaff &
        echo '{"label": "Starting...", "label_size": 30, "label_color": "#aaa", "icon_color": "#aaa"}'
        sleep 3s
    fi
fi
json=$(hubstaff status)
error=$(jq -r .error <<< "$json")
if [[ $error != "null" ]]; then
    echo '{"label": "Offline", "label_size": 30, "label_color": "#555", "icon_color": "#555"}'
    exit 0
fi

tracking=$(echo "$json" | jq -r '.tracking')
tracked_today=$(echo "$json" | jq -r '.active_project.tracked_today')
tracked_today=${tracked_today%:*}

if [[ $tracking == "null" ]]; then
    exit 0
fi

if [[ $tracking == "true" ]]; then
    tracking=""
    msg="$tracking\n$tracked_today"
    echo "{\"label_color\": \"#fff\", \"label_size\": 60, \"icon_color\": \"#1f95ff\", \"color\": \"#294dff\", \"label\": \"$msg\"}"
else
    tracking=""
    msg="$tracking\n$tracked_today"
    echo "{\"label_color\": \"#fff\", \"label_size\": 60, \"icon_color\": \"#ffffff\", \"color\": \"#000000\", \"label\": \"$msg\"}"
fi

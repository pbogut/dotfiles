#!/usr/bin/env bash
#=================================================
# name:   light
# author: Pawel Bogut <pbogut@pbogut.me>
# date:   08/04/2025
#=================================================
host="$(secret homeassistant/mqtt/host)"
user="$(secret homeassistant/mqtt/user)"
pass="$(secret homeassistant/mqtt/pass)"

device="$1"
set_action="$2"
get_action=${set_action^^}

echo mosquitto_sub -h "$host" -t "stat/$device/$get_action" -u "$user" -P "$pass"
mosquitto_sub -h "$host" \
    -t "stat/$device/$get_action" \
    -u "$user" \
    -P "$pass" |
    while read -r state; do
        if [[ $state == "ON" ]]; then
            icon="󰌵"
        elif [[ $state == "OFF" ]]; then
            icon="󰌶"
        else
            icon="󱧣"
        fi
        echo '{"label": "'"$state"'", "label_size": 30, "icon_text": "'"$icon"'"}'
    done &

mosquitto_pub -h "$host" -t "cmnd/$device/$set_action" -u "$user" -P "$pass" -m "STATUS"
while read -r message; do
    mosquitto_pub -h "$host" -t "cmnd/$device/$set_action" -u "$user" -P "$pass" -m "$message"
done

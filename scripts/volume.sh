#!/bin/bash
#=================================================
# name:   volume.sh
# author: Pawel Bogut <https://pbogut.me>
# date:   10/09/2021
#=================================================

action=$1
name=$2
id=$(pulsemixer --list-sinks | grep "$name" | awk '{print $3}' | sed 's/,//')

if [[ -z $name ]]; then
  id=""
else
  name="Name: $name"
  id="--id $id"
fi

if [[ $action == "down" ]]; then
  # shellcheck disable=2086
  pulsemixer --change-volume -1 $id
elif [[ $action == "up" ]]; then
  # shellcheck disable=2086
  pulsemixer --change-volume +1 $id
fi
# shellcheck disable=2086
pulsemixer --get-volume $id | awk '{print $1}' > "$XDG_RUNTIME_DIR/wob.sock"

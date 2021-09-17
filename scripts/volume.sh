#!/bin/bash
#=================================================
# name:   volume.sh
# author: Pawel Bogut <https://pbogut.me>
# date:   10/09/2021
#=================================================

action=$1

if [[ $action == "down" ]]; then
  pulsemixer --change-volume -5
elif [[ $action == "up" ]]; then
  pulsemixer --change-volume +5
fi

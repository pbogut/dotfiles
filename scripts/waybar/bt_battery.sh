#!/usr/bin/env bash
#=================================================
# name:   bt_battery
# author: author <author_contact>
# date:   14/01/2024
#=================================================
mac="$1"
threashold="${2:-25}"

if [[ $mac == "" ]]; then
    echo "Mac address not provided."
    exit 1
fi

pct=$(bluetoothctl info "$mac" |
    grep -F 'Battery Percentage' |
    sed -E 's,.*\(([0-9]+)\)$,\1,')

if [[ $pct == "" ]]; then
    exit 0
fi

if [[ $pct -gt $threashold ]]; then
  exit 0
fi

echo "${pct}%"

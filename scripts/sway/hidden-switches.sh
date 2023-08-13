#!/usr/bin/env bash
#=================================================
# name:   hidden-switches
# author: author <author_contact>
# date:   13/07/2023
#=================================================
dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

host="$(hostname)"

light1="<big> </big> $("$dir/openhab-widget.sh" show Shelly_Office_Light1)  - Light 1"
light2="<big> </big> $("$dir/openhab-widget.sh" show Shelly_Office_Light2)  - Light 2"

[[ $host == "silverspoon" ]] && conservation="<big> </big> $("$dir/conservation.sh")  - Conservation Mode"

options="$light1
$light2
  Close"

if [[ $host == "silverspoon" ]]; then
  options="$light1
$light2
$conservation
  Close"
fi

result=$(echo "$options" | wofi --cache-file /dev/null --dmenu -i --width 300 --xoffset 1620 -m)

if [[ $light1 == "$result" ]]; then
  "$dir/openhab-widget.sh" toggle Shelly_Office_Light1
elif [[ $light2 == "$result" ]]; then
  "$dir/openhab-widget.sh" toggle Shelly_Office_Light2
fi

if [[ $host == "silverspoon" ]]; then
  if [[ $conservation == "$result" ]]; then
    "$dir/conservation.sh" toggle
  fi
fi

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
light3="<big> </big> $("$dir/homeassistant-widget.sh" show switch.office_light_switch_2)  - Office LED Panel"

[[ $host == "silverspoon" ]] && conservation="<big> </big> $("$dir/conservation.sh")  - Conservation Mode"

options="$light3
$light1
$light2
  Close"

if [[ $host == "silverspoon" ]]; then
  options="BT Restart
$light3
$light1
$light2
$conservation
  Close"
fi

result=$(echo "$options" | wofi --cache-file /dev/null --dmenu -i --width 300 --xoffset 1620 -m)

if [[ "BT Restart" == "$result" ]]; then
  sudo systemctl restart bluetooth
  rfkill unblock all
  blueman-manager &
fi
if [[ $light1 == "$result" ]]; then
  "$dir/openhab-widget.sh" toggle Shelly_Office_Light1
elif [[ $light2 == "$result" ]]; then
  "$dir/openhab-widget.sh" toggle Shelly_Office_Light2
elif [[ $light3 == "$result" ]]; then
  "$dir/homeassistant-widget.sh" toggle switch.office_light_switch_2
fi

if [[ $host == "silverspoon" ]]; then
  if [[ $conservation == "$result" ]]; then
    "$dir/conservation.sh" toggle
  fi
fi

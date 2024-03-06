#!/usr/bin/env bash
#=================================================
# name:   logipro
# author: author <author_contact>
# date:   10/08/2023
#=================================================
pct=$(cat /sys/class/power_supply/hidpp_battery_*/capacity | tail -n1)
status=$(cat /sys/class/power_supply/hidpp_battery_*/status | tail -n1)

# echo "$pct"
# echo "$status"

if [[ $pct == "" ]]; then
  exit 0
fi

if [[ $status == "Charging" ]]; then
  echo "<span color='#ed7f21'></span>"
elif [[ $status == "Full" ]]; then
  echo "<span color='#66cc99'></span> $pct%"
elif [[ $pct -le 15 ]]; then
  echo "<span background='#f53c3c'>$pct%</span>"
elif [[ $pct -le 20 ]]; then
  echo "<span color='#ffa000'>$pct%</span>"
elif [[ $pct -le 25 ]]; then
  echo "<span>$pct%</span>"
fi

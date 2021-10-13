#!/usr/bin/env bash
#=================================================
# name:   hibarnate-if-battery-is-low
# author: Pawel Bogut <https://pbogut.me>
# date:   12/10/2021
#=================================================
icon="/usr/share/icons/gnome/32x32/devices/battery.png"
limit="4"
notify="5"

battery="$(acpi | sed -E 's,^.*? ([0-9]+)%.*?$,\1,')"

if [[ $notify -gt $battery ]] || [[ $notify -eq $battery ]]; then
  dunstify -I $icon \
    "Low battery, pleas charge or system will be hibernated when battery level drops to $limit%"
fi

if [[ $limit -gt $battery ]] || [[ $limit -eq $battery ]]; then
  yad \
    --title="Hibernating..." \
    --text "Battery level: $battery%\n\nSystem is going to be hibernated.\n\nClick cancel to prevent it. " \
    --image $icon \
    --question \
    --timeout=30 \
    --timeout-indicator=bottom

  result=$?

  # if cancel clicked or esc hit
  if [[ $result -eq 1 ]] || [[ $result -eq 252 ]]; then
    exit 1
  else
    sudo systemctl hibernate
  fi
fi

#!/usr/bin/env bash
#=================================================
# name:   hibarnate-if-battery-is-low
# author: Pawel Bogut <https://pbogut.me>
# date:   12/10/2021
#=================================================
icon="/usr/share/icons/gnome/32x32/devices/battery.png"
limit="4"
notify="5"
interval=60

usage() {
  echo "Ussage: ${0##*/} [OPTIONS]"
  echo ""
  echo "Options:"
  echo "  -D, --daemon      run in daemon mode"
  echo "  -i, --interval    delay between each check in daemon mode"
  echo ""
  echo "  -h, --help        display this help and exit"
}

battery_level() {
  battery="$(acpi | sed -E 's,^.*? ([0-9]+)%.*?$,\1,')"
  echo "$battery"
}

notify() {
  dunstify -I $icon \
    "Low battery level ($battery%), please charge or system will be hibernated when battery level drops to $limit%"
}

hibernate() {
  yad \
    --title="Hibernating..." \
    --text "Battery level: $battery%\n\nSystem is going to be hibernated.\n\nClick cancel to prevent it." \
    --image $icon \
    --question \
    --timeout=30 \
    --timeout-indicator=bottom

  result=$?

  # if cancel clicked or esc hit
  if [[ ! $result -eq 1 ]] && [[ ! $result -eq 252 ]]; then
    systemctl hibernate
  fi
}

power_status() {
  if [[ -n "$(acpi | grep 'Charging')" ]]; then
    echo "charging"
  elif [[ -n "$(acpi | grep 'Discharging')" ]]; then
    echo "discharging"
  fi
}

check_notification() {
  battery=$(battery_level)
  if [[ $notify -gt $battery ]] || [[ $notify -eq $battery ]]; then
    if [[ $(power_status) == "discharging" ]]; then
      notify
    fi
  fi
  if [[ $limit -gt $battery ]] || [[ $limit -eq $battery ]]; then
    if [[ $(power_status) == "discharging" ]]; then
      hibernate
    fi
  fi
}

while test $# -gt 0; do
  case "$1" in
    --interval|--interval=*|-i)
      if [[ $1 =~ --[a-z]+= ]]; then
        _val="${1//--interval=/}"
        shift
      else
        _val="$2"
        shift; shift
      fi
      interval="$_val"
      ;;
    --daemon|-D)
      daemon=1
      shift
      ;;
    --help|-h)
      usage
      exit 0
      ;;
    *)
      usage
      exit 1
      ;;
  esac
done

if [[ $daemon -eq 1 ]]; then
  while :; do
    check_notification
    sleep "${interval}s";
  done
fi

check_notification

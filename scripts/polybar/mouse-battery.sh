#!/usr/bin/env bash
#=================================================
# name:   mouse-battery
# author: Pawel Bogut <https://pbogut.me>
# date:   11/04/2022
#=================================================
cycle=0                     #init cycle
slp=0.2                     #sleep for tick (tick / 1000)
tick=200                    #tick every n miliseconds
refresh=1800                 #refresh every n seconds
refresh=$((refresh * 1000)) #convert to mili seconds

state="50"
action="Discharging"

refresh() {
  update_state
  show_state
}

info() {
  refresh
  notify-send -i mouse "Mouse Battery" "$state% $action" > /dev/null 2>&1
}

update_state() {
  power_supply=""
  while read file; do
    if [[ $(cat $file) =~ "Gaming Mouse" ]]; then
      power_supply=$(dirname $file)
      break
    fi
  done <<< $(ls /sys/class/power_supply/*/model_name)

  state=$(cat $power_supply/capacity)
  action=$(cat $power_supply/status)
}

show_state() {
  icon=""
  color=""

  if [[ $action == "Full" ]]; then
    color="%{u#2bb34b}" #green
    icon=""
  elif [[ $state -gt 80 ]]; then
    color="%{u#2bb34b}" #green
    icon=""
  elif [[ $state -gt 60 ]]; then
    color="%{u#2e9ef4}" #blue
    icon=""
  elif [[ $state -gt 40 ]]; then
    color="%{u#2e9ef4}" #blue
    icon=""
  elif [[ $state -gt 20 ]]; then
    color="%{u#2e9ef4}" #yellow
    icon=""
  else
    color="%{u#bd2c40}" #red
    icon=""
  fi

  if [[ $action == "Full" || $action == "Unknown" ]]; then
    echo "${color}%{+u}${icon}%{-u}"
  elif [[ $action == "Discharging" && $state -lt 25 ]]; then
    echo "${color}%{+u}${icon}%{-u}"
  else
    echo ""
  fi
}

trap "refresh" SIGRTMIN+1
trap "info" SIGRTMIN+2

update_state
show_state

while true; do
  if [[ $cycle -ge $((refresh / tick)) ]]; then
    update_state
    show_state
    cycle=0
  fi
  cycle=$((cycle + 1))
  sleep ${slp}s
  wait
done

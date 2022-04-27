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
  notify-send -i mouse "Mouse Battery" "$state% $action"
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
  if [[ $action == "Full" ]]; then
    echo "%{u#2bb34b}%{+u}%{-u}" #green
  elif [[ $action == "Unknown" ]] && [[ $state -gt 75 ]]; then
    echo "%{u#2bb34b}%{+u}%{-u}" #green
  elif [[ $action == "Unknown" ]] && [[ $state -gt 50 ]]; then
    echo "%{u#2e9ef4}%{+u}%{-u}" #blue
  elif [[ $action == "Unknown" ]] && [[ $state -gt 25 ]]; then
    echo "%{u#bdbd40}%{+u}%{-u}" #yellow
  elif [[ $action == "Unknown" ]] && [[ $state -gt 0 ]]; then
    echo "%{u#bdbd40}%{+u}%{-u}" #yellow
  elif [[ $action == "Discharging" ]] && [[ $state -lt 10 ]]; then
    echo "%{u#bd2c40}%{+u}%{-u}" #red
  elif [[ $action == "Discharging" ]] && [[ $state -lt 25 ]]; then
    echo "%{u#bdbd40}%{+u}%{-u}" #yello
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

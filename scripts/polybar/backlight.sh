#!/bin/env bash
#=================================================
# name:   backlinght.sh
# author: Pawel Bogut <https://pbogut.me>
# date:   21/05/2021
#=================================================
cycle=0    #init cycle
slp=0.2    #sleep for tick (tick / 1000)
tick=200   #tick every n miliseconds
refresh=5  #refresh every n seconds
refresh=$((refresh * 1000)) #convert to mili seconds

max_brightness=$(cat /sys/class/backlight/intel_backlight/max_brightness)
step=$(($max_brightness / 20))

state=$(cat /sys/class/backlight/intel_backlight/brightness)
last_state=$state

light_up() {
  state=$(($state + $step))
  echo $state | sudo tee /sys/class/backlight/intel_backlight/brightness
  update_state
  show_state
}

light_down() {
  state=$(($state - $step))
  echo $state | sudo tee /sys/class/backlight/intel_backlight/brightness
  update_state
  show_state
}

light_full() {
  update_state
  if [[ $state == $max_brightness ]]; then
    echo $last_state | sudo tee /sys/class/backlight/intel_backlight/brightness
    state=$last_state
  else
    last_state=$state
    echo $max_brightness | sudo tee /sys/class/backlight/intel_backlight/brightness
    state=$max_brightness
  fi
  show_state
}

update_state() {
  state=$(cat /sys/class/backlight/intel_backlight/brightness)
}

show_state() {
  echo $(($state * 100 / $max_brightness))%
}

trap "light_up"   SIGRTMIN+1
trap "light_down" SIGRTMIN+2
trap "light_full" SIGRTMIN+3

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

#!/bin/env zsh
#=================================================
# name:   bt-connection.zsh
# author: Pawel Bogut <https://pbogut.me>
# date:   09/04/2021
#=================================================
cycle=0    #init cycle
tick=1   #tick every n secnds
refresh=3 #refresh every n seconds

state="off"
address="$1"
headphones_icon=/usr/share/icons/oxygen/base/48x48/devices/audio-headphones.png


__connect() {
    bluetoothctl connect $address > /dev/null 2>&1
    if [[ $? == 0 ]]; then
        notify-send -i $headphones_icon "Connected to $address"
    else
        notify-send -i network-error "Can't connect to $address"
    fi
}

__disconnect() {
    bluetoothctl disconnect $address > /dev/null 2>&1
    if [[ $? == 0 ]]; then
        notify-send -i $headphones_icon "Disconnected from $address"
    else
        notify-send -i network-error "Can't disconnect from $address"
    fi
}

switch_state() {
	update_state
	if [[ $state == "on" ]]; then
    notify-send -i network-transmit  "Disconnecting..."
    __disconnect
		state="off"
	else
    notify-send -i network-transmit  "Connecting..."
    __connect
		state="on"
	fi
	show_state
}

update_state() {
	state="on"
  stat=$(hcitool con | grep $address)
  if [[ "$stat" == "" ]]; then
    state="off"
  fi
}

show_state() {
	if [[ $state == "on" ]]; then
		echo 
	else
		echo 
	fi
}

trap "switch_state" USR1

update_state
show_state

while true; do
  if [[ $cycle -ge $((refresh / tick)) ]]; then
    update_state
    show_state
    cycle=0
  fi
	cycle=$((cycle + 1))
	sleep ${tick}s
	wait
done

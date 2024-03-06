#!/bin/bash
#=================================================
# name:   memwatch.sh
# author: Pawel Bogut <https://pbogut.me>
# date:   25/09/2018
#=================================================

while :; do
    sleep 5s;
    if [[ $(grep MemAvailable /proc/meminfo | awk '{print $2}') -lt 500000 ]]; then
        notify-send -i /usr/share/icons/gnome/48x48/emblems/emblem-important.png "Running low on memory"
    fi
    if [[ $(grep MemAvailable /proc/meminfo | awk '{print $2}') -lt 250000 ]]; then
        notify-send -i /usr/share/icons/gnome/48x48/emblems/emblem-important.png "I'm killing it before it lay eggs"
        sudo killall -9 barriers
        flatpak kill org.ferdium.Ferdium
    fi
    if [[ $(grep MemAvailable /proc/meminfo | awk '{print $2}') -lt 150000 ]]; then
        notify-send -i /usr/share/icons/gnome/48x48/emblems/emblem-important.png "I'm killing it before it lay eggs"
        sudo killall -9 barriers
        sudo killall -9 qutebrowser
        sudo killall -9 chrome
        sudo killall -9 java
        flatpak kill org.ferdium.Ferdium
    fi
done

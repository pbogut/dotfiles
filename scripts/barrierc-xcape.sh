#!/usr/bin/env bash
#=================================================
# name:   barrierc-xcape
# author: Pawel Bogut <https://pbogut.me>
# date:   23/10/2021
#=================================================
barrierc --disable-crypto --no-daemon "$1" | while read line; do
  if [[ $line =~ "entering screen" ]]; then
    killall xcape -9
  fi
  if [[ $line =~ "leaving screen" ]]; then
    setxkbmap -option 'caps:ctrl_modifier'
    xcape -e 'Caps_Lock=Escape'
    xcape -e 'Control_L=Escape'
    xcape -e 'Shift_L=parenleft'
    xcape -e 'Shift_R=parenright'
  fi
done

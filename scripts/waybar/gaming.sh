#!/usr/bin/env bash
#=================================================
# name:   gaming
# author: author <author_contact>
# date:   09/09/2023
#=================================================
toggle=false
if [[ $1 == '--toggle' ]]; then
  toggle=true
fi

if swaymsg -t get_outputs | jq '.[].rect.y' | grep 2000 > /dev/null; then
  if $toggle; then
    sway 'output DP-1 pos 1920 0'
  fi
  echo " "
else
  if $toggle; then
    sway 'output DP-1 pos 1920 2000'
  fi
  echo " "
fi

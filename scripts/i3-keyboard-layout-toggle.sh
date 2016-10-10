#!/bin/bash
# toggles through keymaps
# The order is:
#   pl
#   pl colemak
#   gb
#   gb colemak
#
#list=( \
#setxkbmap gb
#setxkbmap gb -variant colemak
#setxkbmap pl
#setxkbmap pl -variant colemak
#)
is_colemak=`setxkbmap -query | grep 'colemak'`
is_pl=`setxkbmap -query | grep 'layout.*pl'`
if [[ -n $is_colemak ]] && [[ -n $is_pl ]]; then
    setxkbmap gb
elif [[ ! -n $is_colemak ]] && [[ -n $is_pl ]]; then
    setxkbmap pl -variant colemak
elif [[ ! -n $is_colemak ]] && [[ ! -n $is_pl ]]; then
    setxkbmap gb -variant colemak
elif [[ -n $is_colemak ]] && [[ ! -n $is_pl ]]; then
    setxkbmap pl
fi

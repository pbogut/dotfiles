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
eval $(setxkbmap -query | sed 's#\<\([^\>]*\):.*\<\(.*\)\>#\1="\2"#' | grep -v options)
# is_colemak=`setxkbmap -query | grep 'colemak'`
# is_pl=`setxkbmap -query | grep 'layout.*pl'`

# echo $layout
# echo $model
# echo $variant

if [[ $variant == "colemak" ]]; then
    setxkbmap pl
else
    setxkbmap pl -variant colemak
fi

# if [[ $variant == "colemak" ]] && [[ $layout == "pl" ]]; then
#     setxkbmap gb
# elif [[ $variant == "" ]] && [[ $layout == "pl" ]]; then
#     setxkbmap pl -variant colemak
# elif [[ $variant == "" ]] && [[ $layout == "gb" ]]; then
#     setxkbmap gb -variant colemak
# elif [[ $variant == "colemak" ]] && [[ $layout == "gb" ]]; then
#     setxkbmap pl
# else
#     setxkbmap pl
# fi

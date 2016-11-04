#!/bin/bash
lay=`setxkbmap -print | grep 'pc+' | sed 's/.*pc+\([^+]*\)+.*/\1/' | sed 's/[()]/ /g' | sed 's/ / -variant /'`
setxkbmap pl
(i3lock $@ --nofork &&
setxkbmap $lay &&
pkill -SIGRTMIN+12 i3blocks) &

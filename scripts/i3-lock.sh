#!/bin/bash
lay=`setxkbmap -print | grep 'pc+' | sed 's/.*pc+\([^+]*\)+.*/\1/' | sed 's/[()]/ /g' | sed 's/ / -variant /'`

setxkbmap pl
i3lock $@
(while pgrep i3lock; do sleep 1s; done; # wait for i3lock to end
setxkbmap $lay
sleep 1s
pkill -SIGRTMIN+12 i3blocks) &

#!/bin/bash
#=================================================
# name:   record.sh
# author: Pawel Bogut <http://pbogut.me>
# date:   10/01/2018
#=================================================
#eval ffmpeg $(slop -f "-video_size %wx%h -framerate 25 -f x11grab -i $DISPLAY.0+%x+%y") $1

filename="$HOME/Videos/$(date +%Y-%m-%d_%H-%M-%S).mp4"
wl-screenrec --geometry "$(slurp)" -f "$filename"
echo ""
result=$(du -h "$filename" | awk '{print "Video saved: " $2 "\nTotal size: " $1 }')
echo "$result"
notify-send "$result" -i camera-video

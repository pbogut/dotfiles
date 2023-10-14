#!/bin/bash
#=================================================
# name:   record.sh
# author: Pawel Bogut <http://pbogut.me>
# date:   10/01/2018
#=================================================
#eval ffmpeg $(slop -f "-video_size %wx%h -framerate 25 -f x11grab -i $DISPLAY.0+%x+%y") $1

wl-screenrec --geometry "$(slurp)" -f ~/Videos/"$(date +%Y-%m-%d_%H-%M-%S)".mp4

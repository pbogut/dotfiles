#!/bin/bash
#=================================================
# name:   record.sh
# author: Pawel Bogut <http://pbogut.me>
# date:   10/01/2018
#=================================================
if pgrep -f wf-record; then
    pkill -INT -x wf-recorder;
    exit 0
fi

mkdir -p "$HOME/Videos/screenrecords"
(
    filename="$HOME/Videos/screenrecords/screenrecord_from_$(date +%Y-%m-%d_%H-%M-%S).mp4"
    wf-recorder -a -g "$(slurp)" -f "$filename"
    echo ""
    result=$(du -h "$filename" | awk '{print "Video saved: " $2 "\nTotal size: " $1 }')
    echo "$result"
    notify-send "Screen recording" "$result" -i camera-video
    lf-term "$filename"
)

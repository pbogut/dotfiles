#!/bin/bash
#=================================================
# name:   record.sh
# author: Pawel Bogut <http://pbogut.me>
# date:   10/01/2018
#=================================================
refresh_waybar() {
    for _ in {1..3}; do
        sleep 0.5
        pkill -RTMIN+21 -x waybar
    done
}

if pgrep -f wf-record; then
    pkill -INT -x wf-recorder;
    refresh_waybar
    exit 0
fi

mkdir -p "$HOME/Videos/screenrecords"
# wl-screenrec --geometry "$(slurp)" -f "$filename"
(
    refresh_waybar &
    filename="$HOME/Videos/screenrecords/screenrecord_from_$(date +%Y-%m-%d_%H-%M-%S).mp4"
    wf-recorder -a -g "$(slurp)" -f "$filename"
    echo ""
    result=$(du -h "$filename" | awk '{print "Video saved: " $2 "\nTotal size: " $1 }')
    echo "$result"
    notify-send "Screen recording" "$result" -i camera-video
    lf-term "$filename"
)

#!/usr/bin/env bash
#=================================================
# name:   light
# author: Pawel Bogut <pbogut@pbogut.me>
# date:   08/04/2025
#=================================================
print_status() {
    if pgrep -f "gpu-screen-recorder" > /dev/null 2>&1; then
        icon="󰑋"
        state="Recording"
        color="#ee0000"
    else
        icon="󰑊"
        state="Rec Off"
        color="#555"
    fi
    echo '{"icon_color": "'"$color"'", "label": "'"$state"'", "label_size": 40, "icon_text": "'"$icon"'"}'
}
while true; do
    sleep 5s;
    print_status
done &

while read -r _message; do
    kill -USR1 "$(pgrep -f "gpu-screen-recorder")"
    echo '{"icon_color": "#00ee00", "label": "Saved!", "label_size": 40, "icon_text": ""}'
    sleep 1.5s;
    print_status
done

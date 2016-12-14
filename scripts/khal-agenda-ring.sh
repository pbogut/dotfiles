#!/bin/bash
# Author: pbogut

while :; do
    khal agenda | grep -v 'Today:' | sed '/[A-Z][a-z]*:/,$d' | (while read l; do
        endtime=$(echo $l | sed 's/[^-]*-\([0-9]*\):\([0-9]*\).*/\1\2/')
        curtime=$(date '+%H%M')
        # display event only if not fineshed yet
        if [[ "$endtime" -gt "$curtime" ]]; then
            has_event=true
            echo '{"full_text": "'`echo $l | sed 's/"/'"'"'/g'`'"}'
            sleep 15s
        fi
    done
    if [[ -z $has_event ]]; then
        sleep 60s #no events so wait a bit longer befor calling khal again
    fi)
done;

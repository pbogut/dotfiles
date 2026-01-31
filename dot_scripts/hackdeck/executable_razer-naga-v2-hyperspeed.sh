#!/usr/bin/env bash
#=================================================
# name:   hubstaff
# author: Pawel Bogut <pbogut@pbogut.me>
# date:   07/02/2025
#=================================================
level=$(razer-cli --battery 'Razer Naga V2 HyperSpeed' | grep charge | awk '{print $2}')
if [[ $level -eq 0 ]]; then
    echo "{\"label_color\": \"#ccc\"}"
    exit 0
fi
if [[ $level -gt 10 ]]; then
    echo "{\"label_color\": \"#fff\", \"label_size\": 60, \"icon_color\": \"#fff\", \"color\": \"#000\", \"label\": \"$level%\"}"
elif [[ $level -gt 5 ]]; then
    echo "{\"label_color\": \"#fff\", \"label_size\": 60, \"icon_color\": \"#ff7806\", \"color\": \"#000\", \"label\": \"$level%\"}"
else
    echo "{\"label_color\": \"#fff\", \"label_size\": 60, \"icon_color\": \"#ff0806\", \"color\": \"#000\", \"label\": \"$level%\"}"
fi

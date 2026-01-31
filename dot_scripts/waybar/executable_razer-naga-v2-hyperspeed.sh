#!/usr/bin/env bash
#=================================================
# name:   hubstaff
# author: Pawel Bogut <pbogut@pbogut.me>
# date:   07/02/2025
#=================================================
level=$(razer-cli --battery 'Razer Naga V2 HyperSpeed' | grep charge | awk '{print $2}')
touch /tmp/razer-naga-v2-hyperspeed.last
last_level=$(cat /tmp/razer-naga-v2-hyperspeed.last | head -n1)
if [[ $level -eq 0 ]]; then
    echo "<span color='#999'>${last_level}%</span>"
    exit 0
fi
echo "$level" > /tmp/razer-naga-v2-hyperspeed.last
if [[ $level -gt 10 ]]; then
    echo "${level}%"
elif [[ $level -gt 5 ]]; then
    echo "<span color='#ff7806'>${level}%</span>"
else
    echo "<span color='#ff0806'>${level}%</span>"
fi

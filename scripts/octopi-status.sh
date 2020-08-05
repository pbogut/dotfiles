#!/bin/bash
#=================================================
# name:   octopi-status.sh
# author: Pawel Bogut <https://pbogut.me>
# date:   25/04/2018
#=================================================
source $HOME/.profile.secret
color="#FFFFFF"
last_percent_file=$TMPDIR/__octoprint_status_last_percent
last_percent="$(cat $last_percent_file 2>/dev/null)"
last_message_file=$TMPDIR/__octoprint_status_last_message
last_message="$(cat $last_message_file 2>/dev/null)"


response=$(curl "$OCTOPI_URL/api/job" \
    --header "X-Api-Key: $OCTOPI_API" \
    2>/dev/null)

message=$(echo $response |
    jq -r '(.job.file.display) + ": " +  (.progress.completion | floor| tostring) + "%"' 2>/dev/null)

percent=$(echo $response |
    jq -r '(.progress.completion | floor| tostring)' 2>/dev/null)

state=$(echo $response |
    jq -r '.state' 2>/dev/null)

if [[ $1 == "3" && $percent == 100 ]]; then
    echo $message > $last_message_file
    exit 0
fi

if [[ $message == "" && $state =~ "Offline" ]]; then
    echo '{"full_text": "Offline", "color": "'$color'"}'
fi

if [[ $message == "" && $state =~ "Online" ]]; then
    echo '{"full_text": "Online", "color": "'$color'"}'
fi

if [[ $last_message == $message ]]; then
    exit 0
fi

echo "" > $last_message_file

if [[ $percent == "100" && $last_percent != "100" ]]; then
    notify-send -i printer-printing "Print finished!
$message"
fi

[[ $percent -gt 49 ]] && color="#FFFF00"  # 50
[[ $percent -gt 74 ]] && color="#00FFFF"  # 75
[[ $percent -eq 100 ]] && color="#00FF00" # 100

if [[ -n $message ]]; then
    echo '{"full_text": '$(echo $message | jq -R)', "color": "'$color'"}'
fi
echo $percent >$last_percent_file

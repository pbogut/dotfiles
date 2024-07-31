#!/usr/bin/env bash
#=================================================
# name:   hubstaff
# author: author <author_contact>
# date:   31/07/2024
#=================================================
json=$(hubstaff status)

tracking=$(echo "$json" | jq -r '.tracking')
#project=$(echo "$json" | jq -r '.active_project.name')
task=$(echo "$json" | jq -r '.active_task.name')
tracked_today=$(echo "$json" | jq -r '.active_project.tracked_today')

if [[ $tracking == "null" ]]; then
    exit 0
fi

if [[ $tracking == "true" ]]; then
    tracking=""
else
    tracking=""
fi

msg="<span color=\"#2e9ef4\">$tracking</span> $task [<span color=\"#2e9ef4\"></span> $tracked_today]"
echo "$msg"

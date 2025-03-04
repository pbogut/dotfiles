#!/usr/bin/env bash
#=================================================
# name:   hubstaff
# author: Pawel Bogut <pbogut@pbogut.me>
# date:   07/02/2025
#=================================================
current=$(asus-menu source)
icon="󰍹"
name="PC"
if [[ $current == "dvi" ]]; then
    icon="󰍹"
    name="PC"
else
    icon="󰌢"
    name="Laptop"
fi
echo '{"label": "'"$name"'", "label_size": 30, "icon_text": "'"$icon"'"}'

while read -r action; do
    if [[ $action == "toggle" ]]; then
        if [[ $current == "dvi" ]]; then
            current=$(asus-menu source hdmi)
            # shellcheck disable=2181
            if [[ $? -eq 0 ]]; then
                icon="󰌢"
                name="Laptop"
            fi
        else
            current=$(asus-menu source dvi)
            # shellcheck disable=2181
            if [[ $? -eq 0 ]]; then
                icon="󰍹"
                name="PC"
            fi
        fi
        current=$(asus-menu source)
        echo '{"label": "'"$name"'", "label_size": 30, "icon_text": "'"$icon"'"}'
    fi
done

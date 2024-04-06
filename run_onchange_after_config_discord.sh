#!/usr/bin/env bash
#=================================================
# name:   run_onchange_after_config_discord
# author: pbogut <pbogut@pbogut.me>
# date:   06/04/2024
#=================================================
#check if jq available
settings_file="$HOME/.config/discord/settings.json"
if [ -x "$(command -v jq)" ]; then
    if ! [ -f "$settings_file" ]; then
        mkdir -p "$(dirname "$settings_file")"
        echo '{}' > "$settings_file"
    fi
    settings=$(cat "$settings_file")
    echo "$settings" | jq '. + {"SKIP_HOST_UPDATE": true}' > "$settings_file"
fi

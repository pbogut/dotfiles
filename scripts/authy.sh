#!/bin/bash
#=================================================
# name:   authy.sh
# author: Pawel Bogut <https://pbogut.me>
# date:   20/08/2019
#=================================================
AUTH_ACCOUNTS_FILE="$HOME/.Accounts.txt" authy.py | rofi -dmenu | awk '{print $2}' | xargs xdotool type --clearmodifiers
# authy.py | rofi -dmenu | awk '{print $2}' | xargs xdotool type --clearmodifiers

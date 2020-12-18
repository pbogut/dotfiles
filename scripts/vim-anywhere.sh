#!/bin/bash
#=================================================
# name:   vim-anywhere.sh
# author: Pawel Bogut <pbogut@ukpos.com> <http://pbogut.me>
# date:   02/03/2017
#=================================================
file="/tmp/$(date +'%s')-$RANDOM.tmp"
if [[ $1 == "--selection" ]]; then
    xsel > $file
fi
if [[ $1 == "--clipboard" ]]; then
    xsel -b > $file
fi
if [[ $1 == "--draft" ]]; then
    xsel -b > $file
    ext=$((
        echo 'md'
        echo 'sql'
        echo 'json'
        echo 'js'
        echo 'php'
        echo 'rb'
        echo 'py'
        echo 'exs'
        ) | rofi -dmenu -p 'ext')
    cd ~/Drafts
    rand=$(head -n1 /dev/urandom | sha256sum | sed 's,^\(.\{8\}\).*,\1,g')
    file="$(date +'%Y-%m-%d_%H:%M:%S')_$rand.$ext"
fi
urxvt -e nvim $file && cat $file | xsel -b

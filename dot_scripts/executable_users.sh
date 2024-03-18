#!/bin/bash
#=================================================
# name:   switch-user.sh
# author: Pawel Bogut <https://pbogut.me>
# date:   15/06/2018
#=================================================
_who() {
    who -u | grep -v 'login screen'
}

if [[ $1 == '--switch' ]]; then
    users=$(_who | sed 's,^\([a-zA-Z_-]*\).*,\1,g' | grep -v "^$(id -un)")
    user=$(echo "$users" | wofi --dmenu -p "switch user")
    [[ -z $user ]] && exit 0

    vtn=$(_who | grep "^$user" | sed 's,^.*tty\([0-9]*\).*$,\1,')
    if [[ -n $vtn ]]; then
        sudo chvt "$vtn"
    fi
fi
if [[ $1 == '--kill' ]]; then
    users=$(who -u | sed 's,^\([a-zA-Z_-]*\).*,\1,g' | grep -v "^$(id -un)")
    user=$(echo "$users" | rofi -dmenu -p "kill user")
    [[ -z $user ]] && exit 0
    vtn=$(_who | grep "^$user" | awk '{ print $6 }')
    [[ -n $vtn ]] && sudo kill "$vtn"
fi

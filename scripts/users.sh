#!/bin/bash
#=================================================
# name:   switch-user.sh
# author: Pawel Bogut <https://pbogut.me>
# date:   15/06/2018
#=================================================
if [[ $1 == '--switch' ]]; then
    users=$(who -u | sed 's,^\([a-zA-Z_-]*\).*,\1,g' | grep -v "^$(id -un)")
    user=$(echo "$users" | rofi -dmenu -p "switch user")
    [[ -z $user ]] && exit 0
    islogged=$(who -u | grep "^$user")
    if [[ -z $islogged ]]; then
        # not loggod
        dm-tool switch-to-greeter
    else
        # logged
        vtn=$(who -u | grep "^$user" | sed 's,^.*tty\([0-9]*\).*$,\1,')
    fi
    if [[ -n $vtn ]]; then
        sudo chvt $vtn
    else
        dm-tool switch-to-greeter
    fi
fi
if [[ $1 == '--kill' ]]; then
    users=$(who -u | sed 's,^\([a-zA-Z_-]*\).*,\1,g' | grep -v "^$(id -un)")
    user=$(echo "$users" | rofi -dmenu -p "kill user")
    [[ -z $user ]] && exit 0
    islogged=$(who -u | grep "^$user")
    vtn=$(who -u | grep "^$user" | awk '{ print $6 }')
    [[ -n $vtn ]] && sudo kill $vtn
fi

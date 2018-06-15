#!/bin/bash
#=================================================
# name:   switch-user.sh
# author: Pawel Bogut <https://pbogut.me>
# date:   15/06/2018
#=================================================
tmp="/tmp/users"
if [[ $1 == '--register' ]]; then
    user=$(id -un)
    touch $tmp
    chmod 777 $tmp >/dev/null 2>&1
    filtered=$(cat $tmp | sed "/^$user:/d")
    echo "$filtered" >$tmp
    echo "$user:$XDG_VTNR" >>$tmp
fi
if [[ $1 == '--switch' ]]; then
    users=$(cat /etc/passwd | grep ':x:[0-9]*:100:' | sed 's,\([^:]*\).*,\1,')
    user=$(echo "$users" | rofi -dmenu)
    islogged=$(dm-tool list-seats 2>/dev/null | grep "UserName='$user'")
    if [[ -z $islogged ]]; then
        # not loggod
        dm-tool switch-to-user $user
    else
        # logged
        vtn=$(cat $tmp | grep "^$user" | sed 's,[^:]*:,,')
    fi
    if [[ -n $vtn ]]; then
        sudo chvt $vtn
        dm-tool switch-to-user $user
    fi
fi

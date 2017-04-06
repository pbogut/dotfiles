#!/bin/bash
#=================================================
# name:   laptop-keyboard.sh
# author: Pawel Bogut <http://pbogut.me>
# date:   24/03/2017
#=================================================


case "$1" in
    disable)
        xinput | grep 'AT Translated Set 2 keyboard' | sed 's/.*id=\([0-9]*\).*(\([0-9]*\).*/\1 \2/' | (read id master
        if [[ -n $id ]]; then
            echo "$id $master" > /tmp/__laptop-keyboard
            xinput float $id
        fi)
        ;;
    enable)
        more /tmp/__laptop-keyboard | (read id master
        if [[ -n $id ]]; then
            xinput reattach $id $master
        fi)
        ;;
    *)
        is_enabled=$(xinput | grep 'AT Translated Set 2 keyboard' | grep 'floating')
        echo "Enable / Disable build in laptop keyboard."
        echo ""
        echo "Status:"
        if [[ $is_enabled == "" ]]; then
            echo -e "\tLaptop keybord is enabled."
        else
            echo -e "\t Laptop keybord is disabled."
        fi
        echo ""
        echo "Usage:"
        echo -e "\t$(basename $0) [enable|disable]"
esac

#!/usr/bin/env bash
#=================================================
# name:   wlsunset
# author: Pawel Bogut <pbogut@pbogut.me>
# date:   01/03/2026
#=================================================
usage() {
    echo "Ussage: ${0##*/} <on|off> [OPTIONS]"
    echo ""
    echo "State:"
    echo "  on     turn on sunset"
    echo "  off    turn off sunset"
    echo "Options:"
    echo "  -h, --help     display this help and exit"
}

while test $# -gt 0; do
    case "$1" in
        on)
            pkill -xf "wlsunset -l 50 -L 17"
            at now <<< "wlsunset -l 50 -L 17" > /dev/null 2>&1
            exit 0
            ;;
        off)
            killall wlsunset -9
            exit 0
            ;;
        --help|-h)
            usage
            exit 0
            ;;
        *)
            usage
            exit 1
            ;;
    esac
done

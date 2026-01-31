#!/usr/bin/env bash
#=================================================
# name:   executable_easyeffects
# author: Pawel Bogut <pbogut@pbogut.me>
# date:   13/01/2026
#=================================================
current=""
type="input"
action="show"

usage() {
    echo "Ussage: ${0##*/} [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -h, --help     display this help and exit"
    echo "  -t, --type     type - input or output [default: input]"
}

while test $# -gt 0; do
    case "$1" in
        toggle)
            action="toggle"
            shift
            ;;
        --type|-t)
            if [[ "$2" == "output" ]] || [[ "$2" == "o" ]] || [[ "$2" == "out" ]]; then
                type="output"
            elif [[ "$2" == "input" ]] || [[ "$2" == "i" ]] || [[ "$2" == "in" ]]; then
                type="input"
            else
                echo "Available types: [input, output]"
                exit 1
            fi
            shift
            shift
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

current=$(easyeffects -s | grep "^${type}:" | sed "s/^${type}:\s//")

if [[ "$action" == "show" ]]; then
    echo "$current"
fi
if [[ "$action" == "toggle" ]]; then
    list=""
    if [[ "$type" == "output" ]]; then
        list=$(easyeffects -p | sed -n '/^Output/,/^$/p' | sed '1d' | grep -v '^$' | cut -f2-)
    elif [[ "$type" == "input" ]]; then
        list=$(easyeffects -p | sed -n '/^Input/,/^$/p' | sed '1d' | grep -v '^$' | cut -f2-)
    fi
    next=$( (echo "$list"; echo "$list") | sed -n "/^${current}$/!d; n; p" | head -n1)
    easyeffects -l "$next"
    echo "$next"
fi

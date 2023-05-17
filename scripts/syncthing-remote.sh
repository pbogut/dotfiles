#!/usr/bin/env bash
#=================================================
# name:   syncthing-remote
# author: author <pbogut@pbogut.me>
# date:   18/09/2022
#=================================================

usage() {
    echo "Ussage: ${0##*/} [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -h, --help     display this help and exit"
}

host=""
while test $# -gt 0; do
    case "$1" in
        --host|--host=*)
            if [[ $1 =~ --[a-z]+= ]]; then
                _val="${1//--host=/}"
                shift
            else
                _val="$2"
                shift; shift
            fi
            host="$_val"
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

port=$(freeport -m 9000)

echo "http://localhost:$port"
echo ""
echo "Press ctrl+c to exit"

gio open "http://localhost:$port" > /dev/null 2>&1
(ssh -L "$port:localhost:8384" "$host" -t "while :; do sleep 10s; done" > /dev/null 2>&1)

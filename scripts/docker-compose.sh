#!/usr/bin/env bash
#=================================================
# name:   docker-compose
# author: Pawel Bogut <pbogut@assuredpharmacy.co.uk>
# date:   03/03/2023
#=================================================

usage() {
    echo "Ussage: ${0##*/} [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  is-up {dir?} checks if docker-compose is up for given directory"
    echo "                 (current directory by default)"
    echo "  -s, --starship this help and exit"
    echo "  -h, --help     display this help and exit"
}

directory="$PWD"
action=""
starship=false
while test $# -gt 0; do
    case "$1" in
        is-up)
            action="is-up"
            shift
            if [ -n "$1" ]; then
                directory=$1
                shift
            fi
            ;;
        --starship|-s)
            starship=true
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

if [[ $action == "is-up" ]]; then
    realpath=$(realpath "$directory")
    while read -r docker_file; do
        docker_dir=$(dirname "$docker_file")
        if [[ "$realpath" == "$docker_dir" ]]; then
            if $starship; then
                echo "up"
            else
                echo "is-up: yes"
            fi
            exit 0
        fi
    done <<< "$(docker-compose ls | tail -n+2 | sed -E "s,[^ ]+[ ]+[^ ]+[ ]+(.*),\1,g")"
    if $starship; then
        echo "down"
        exit 0
    else
        echo "is-up: no"
        exit 5
    fi
fi

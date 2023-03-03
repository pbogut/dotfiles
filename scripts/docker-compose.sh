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
    echo "  -h, --help     display this help and exit"
}

while test $# -gt 0; do
    case "$1" in
        is-up)
            shift
            if [ -z "$1" ]; then
                directory="."
            else
                directory=$1
                shift
            fi
            realpath=$(realpath "$directory")
            while read -r docker_file; do
                docker_dir=$(dirname "$docker_file")
                if [[ "$realpath" == "$docker_dir" ]]; then
                    echo "is-up: yes"
                    exit 0
                fi
            done <<< "$(docker-compose ls | tail -n+2 | sed -E "s,[^ ]+[ ]+[^ ]+[ ]+(.*),\1,g")"
            echo "is-up: no"
            exit 5
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

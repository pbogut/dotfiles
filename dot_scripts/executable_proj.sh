#!/bin/bash
#=================================================
# name:   proj.sh
# author: Pawel Bogut <pbogut@ukpos.com> <http://pbogut.me>
# date:   29/03/2017
#=================================================

while [[ $# > 0 ]] ; do
    case $1 in
        --shell)
            shell=$2
            shift;;
        --title)
            title=$2
            shift;;
        --run-and-then)
            ${@:3}
            $2
            break;;
        --term-and-shell)
            cmd=${@:2}
            ($TERMINAL -title "${title:-$cmd}" -e $0 --run-and-then ${shell:-$SHELL} "$cmd" &)
            break;;
        --term)
            ($TERMINAL -title "${title:-$cmd}" -e "${@:2}" &)
            break;;
        --run)
            ("${@:2}" &)
            break;;
    esac
    # echo $1 #debuging
    shift
done

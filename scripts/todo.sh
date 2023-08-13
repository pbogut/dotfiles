#!/bin/bash
#=================================================
# name:   todo.sh
# author: Pawel Bogut <https://pbogut.me>
# date:   25/01/2019
#=================================================
_list() {
        todo list
        echo ":new"
        echo ":quick-new"
}

selection=$(_list | tac | rofi -dmenu)
# shellcheck disable=2001
id=$(echo "$selection" | sed 's/\[.\][[:space:]]*\([[:digit:]]*\).*/\1/g')

if [[ $selection == ":quick-new" ]]; then
        tmp=$(mktemp)
        $TERMINAL -t FLOATING_WINDOW -e zsh -ic "vim $tmp || rm $tmp"
        if [[ -f $tmp ]]; then
                sed -E 's/ @([a-z]+) / -l \1 /g' -i "$tmp"
                sed -E 's/ @([a-z]+)$/ -l \1/g' -i "$tmp"
                sed -E 's/^@([a-z]+) /-l \1 /g' -i "$tmp"
                sed -E 's/^@([a-z]+)$/-l \1/g' -i "$tmp"
                result="$(xargs todo new < "$tmp")"
                dunstify "$result"
        fi
elif [[ $selection == ":new" ]]; then
        $TERMINAL -t FLOATING_WINDOW -e zsh -ic "todo new"
elif [[ -n $id ]]; then
        $TERMINAL -t FLOATING_WINDOW -e zsh -ic "todo edit $id"
fi

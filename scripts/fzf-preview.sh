#!/bin/bash
#=================================================
# name:   fzf-preview.sh
# author: Pawel Bogut <https://pbogut.me>
# date:   30/01/2021
#=================================================

file="$1"

print_file() {
    type bat > /dev/null 2>&1
    if [[ $? == 0 ]]; then
        bat -p --color=always "$file"
    else
        cat "$file"
    fi
}

print_diff() {
    git diff "$file" > /dev/null 2>&1
    if [[ $? == 0 ]]; then
        git diff --color=always -- "$file" | sed 1,4d 
    fi
}

if [[ -f $file ]]; then
    (print_diff; print_file) | head -n 250
else 
    echo "Preview is not available."
fi

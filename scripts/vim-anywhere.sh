#!/bin/bash
#=================================================
# name:   vim-anywhere.sh
# author: Pawel Bogut <pbogut@ukpos.com> <http://pbogut.me>
# date:   02/03/2017
#=================================================
file="/tmp/$(date +'%s')-$RANDOM.tmp"
if [[ $1 == "--selection" ]]; then
    xsel > $file
fi
nvim-qt $file && cat $file | xsel -b

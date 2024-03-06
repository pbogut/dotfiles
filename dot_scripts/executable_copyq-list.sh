#!/bin/bash
#=================================================
# name:   copyq-list.sh
# author: Pawel Bogut <https://pbogut.me>
# date:   10/01/2019
#=================================================
last=$(copyq count)
# for (( c=$(expr $last - 1); c>=0; c-- )); do
for (( c=0; c<=$(expr $last - 1); c++ )); do
    content=$(copyq read $c | cut -b1-200 | sed ':a;N;$!ba;s,\n,¬ ,g' | cut -b1-200)
    echo "$c | $content"
done

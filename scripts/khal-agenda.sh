#!/usr/bin/env bash
#=================================================
# name:   khal-agenda
# author: Pawel Bogut <https://pbogut.me>
# date:   24/11/2021
#=================================================
width=$(stty size | awk '{print $2}')
width=$(( "$width" - 3 ))
sep=""
x=0; while test "$x" -lt "$width"; do sep="$sep─"; x=$(( "$x" + 1 )); done;

echo "╭$sep"
khal list --format \
  '│ {calendar}: {cancelled}{start-date} {start-style}{to-style}{end-style} : {title}{description-separator}{description}{location}{repeat-symbol}{alarm-symbol}' \
  'now' \
  | sed -ne '/^│/p' \
  | column -tl 3

echo "╰$sep"

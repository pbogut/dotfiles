#!/usr/bin/env bash
#=================================================
# name:   logipro
# author: author <author_contact>
# date:   10/08/2023
#=================================================
battery=$(dualsensectl battery)
pct=$(awk '{print $1}' <<< "$battery")
status=$(awk '{print $2}' <<< "$battery")


if [[ $pct == "" ]]; then
  exit 0
fi

if [[ $status == "charging" ]]; then
  echo "<span color='#ed7f21'></span> $pct%"
elif [[ $status == "full" ]]; then
  echo "<span color='#66cc99'></span> $pct%"
elif [[ $pct -le 15 ]]; then
  echo "<span background='#f53c3c'>$pct%</span>"
elif [[ $pct -le 20 ]]; then
  echo "<span color='#ffa000'>$pct%</span>"
else
  echo "<span>$pct%</span>"
fi

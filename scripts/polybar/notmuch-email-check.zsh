#!/bin/env zsh
#=================================================
# name:   notmuch-email-check.zsh
# author: Pawel Bogut <https://pbogut.me>
# date:   22/12/2020
#=================================================
cycle=0    #init cycle
tick=0.2   #tick every n secnds
refresh=6 #refresh every n seconds

main_action() {
  unread="$(notmuch search tag:unread and tag:inbox | wc -l)"
  inbox="$(notmuch search tag:inbox | wc -l)"
  # if [[ $unread != "0" ]] || [[ $inbox != "0" ]]; then
  if [[ $unread != "0" ]]; then
    echo $unread/$inbox
  else
    echo ""
  fi
}

main_action

while true; do
  if [[ $cycle -ge $((refresh / tick)) ]]; then
    main_action
    cycle=0
  fi
  cycle=$((cycle + 1))
  sleep ${tick}s
  wait
done

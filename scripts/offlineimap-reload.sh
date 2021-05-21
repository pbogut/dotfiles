#!/bin/bash
#=================================================
# name:   offlineimap-reload.sh
# author: Pawel Bogut <https://pbogut.me>
# date:   20/04/2021
#=================================================
clear
# list=$(cat ~/.offlineimaprc |
#   grep '^accounts' |
#   sed 's/accounts = /all,/g' |
#   sed 's/,/\n/g' |
#   rofi -dmenu)

acc=$(cat ~/.offlineimaprc |
  grep '^accounts' |
  sed 's/accounts = /all,/g' |
  sed 's/,/\n/g' |
  fzf --prompt 'Select Account: ')

if [[ $acc == "" ]]; then
  echo 'No account selected!'
elif [[ $acc == "all" ]]; then
  echo 'Update all accounts'
  OFFLINEIMAP_INBOX_ONLY=1 offlineimap
else
  echo "Selected account: $acc"
  OFFLINEIMAP_INBOX_ONLY=1 offlineimap -a $acc
fi

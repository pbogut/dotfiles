#!/bin/env zsh
#=================================================
# name:   shadowplay.sh
# author: Pawel Bogut <https://pbogut.me>
# date:   24/03/2022
#=================================================
cycle=0    #init cycle
tick=1   #tick every n secnds
refresh=10 #refresh every n seconds

main_action() {
  interface=$(sudo wg show | grep '^interface' | sed 's/^interface: //g' | grep -v '^$' | tr '\n' ',' | sed 's/,$//g')
  if [[ ! -z $interface ]]; then

    echo "%{F#e60053}%{F-} ($interface)"
    #echo "VPN ($interface)"
  else
    echo ''
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
done

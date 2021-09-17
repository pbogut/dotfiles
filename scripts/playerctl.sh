#!/bin/env bash
#=================================================
# name:   playerctl.sh
# author: Pawel Bogut <https://pbogut.me>
# date:   16/09/2021
#=================================================

current_file="$TMPDIR/playerctl.current"

init() {
  touch "$current_file"
  current_player=$(playerctl -l | grep "$(cat "$TMPDIR/playerctl.current")" | head -n1)
  echo "$current_player" > "$current_file"
}

get_current_player() {
  current_player=$(playerctl -l | grep "$(cat "$TMPDIR/playerctl.current")" | head -n1)
  echo "$current_player" | tee "$current_file"
}

set_current_player() {
  echo "$1" > "$current_file"
}

ctl() {
  playerctl -p "$(get_current_player)" $@
}

init

if [[ "$1" == "next-player" ]]; then
  ctl pause #pause current
  is_next=0
  set_current_player "$(playerctl -l | head -n 1)"
  playerctl -l | while read player; do
    if [[ $is_next -eq 1 ]]; then
      set_current_player "$player"
      is_next=0
    fi
    if [[ "$player" == "$current_player" ]]; then
      is_next=1
    fi
  done
  ctl play #play new
elif [[ "$1" == "prev-player" ]]; then
  ctl pause #pause current
  is_next=0
  set_current_player "$(playerctl -l | tail -n 1)"
  playerctl -l | sort -r | while read player; do
    if [[ $is_next -eq 1 ]]; then
      set_current_player "$player"
      is_next=0
    fi
    if [[ "$player" == "$current_player" ]]; then
      is_next=1
    fi
  done
  ctl play #play new
else
  ctl $@
fi


#!/usr/bin/env bash
#=================================================
# name:   mousescreenlock.sh
# author: Pawel Bogut <https://pbogut.me>
# date:   21/03/2022
# desc:   Locks mouse to game screen, usefull in
#         some games to prevent monitor switching
#=================================================

usage() {
  echo "Ussage: ${0##*/} [OPTIONS]"
  echo ""
  echo "Options:"
  echo "  -h, --help     display this help and exit"
}

while test $# -gt 0; do
  case "$1" in
    lock)
      ;;
    unlock)
      killall -9 xpointerbarrier
      pkill -9 -f mousescreenlock.sh
      ;;
    --help|-h)
      usage
      exit 0
      ;;
    *)
      usage
      exit 1
      ;;
  esac
done


lock_gap=${LOCK_GAP:-15}

# kill all subprocesses on exit
trap 'trap " " SIGTERM; kill 0; wait;' SIGINT SIGTERM

is_fullscreen() {
  xprop -id $1 | grep _NET_WM_STATE_FULLSCREEN > /dev/null 2>&1
  if [[ $? -eq 0 ]]; then
    echo 1
  else
    echo 0
  fi
}


# (i3-match -Sm :evtype=window change=fullscreen_mode -o container/window container/name &
# i3-match -Sm :evtype=window change=focus -o container/window container/name &) |
#   while read winid title; do

#   if [[ $(is_fullscreen $winid) -eq 1 ]]; then
#     notify-send -t 2500 -u low "Lock mouse for $title"
#     #xpointerbarrier 1 1 1 1 &
#     xpointerbarrier 0 0 0 0 &
#   else
#     killall xpointerbarrier > /dev/null 2>&1
#   fi
# done

(echo ""; i3-match -Sm :evtype=workspace -o workspace/name) |
  while read _line; do
    wsname=$(i3-msg -t get_workspaces | jq -r '.[] | select(.focused == true).name')
    echo $wsname

    if [[ $wsname == "0: gaming" ]]; then
      notify-send -t 2500 -u low "Lock mouse for $wsname"
      xpointerbarrier $lock_gap $lock_gap $lock_gap $lock_gap &
    else
      killall xpointerbarrier > /dev/null 2>&1
    fi
  done
# required by trap
wait

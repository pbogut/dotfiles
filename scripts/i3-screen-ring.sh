#!/usr/bin/env bash
#=================================================
# name:   i3-screen-ring
# author: Pawel Bogut <https://pbogut.me>
# date:   14/03/2022
#=================================================

get_next() {
  current=$(get_current)
  next=0
  get_all | while read output; do
    if [[ $next -eq 1 ]]; then
      echo $output
      break
    fi
    if [[ $output == $current ]]; then
      next=1
    fi
  done
}

get_prev() {
  current=$(get_current)
  prev=""
  get_all | while read output; do
    if [[ -z $prev ]]; then
      prev=$output
    elif [[ $output == $current ]]; then
      echo $prev
      break
    fi
    prev=$output
  done
}

get_current() {
  i3-msg -t get_workspaces | jq '.[] | select(.focused == true).output'
}

get_all() {
  i3-msg -t get_outputs | jq '.[] | select(.active == true).name'
  i3-msg -t get_outputs | jq '.[] | select(.active == true).name'
}

usage() {
  echo "Ussage: ${0##*/} [OPTIONS]"
  echo ""
  echo "Options:"
  echo "  -h, --help     display this help and exit"
}

action=""
dest=""
while test $# -gt 0; do
  case "$1" in
    --move-win|-mw)
      action="move-win"
      shift
      ;;
    --next|-n)
      dest=$(get_next)
      shift
      ;;
    --prev|-p)
      dest=$(get_prev)
      shift
      ;;
    --focus|-f)
      action="focus"
      shift
      ;;
    --move|-m)
      action="move"
      shift
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

case "$action" in
  "move-win")
    focus_id=$(xdotool getwindowfocus)
    ~/.scripts/i3-create-empty-workspace.py --move
    i3-msg move workspace to output "$dest"
    xdotool windowfocus --sync "$focus_id"
    ;;
  "move")
    focus_id=$(xdotool getwindowfocus)
    i3-msg move workspace to output $dest
    xdotool windowfocus --sync $focus_id
    ;;
  "focus")
    i3-msg focus output $dest
esac

# focus_id=$(xdotool getwindowfocus)
# i3-msg move workspace to output next
# xdotool windowfocus --sync $focus_id

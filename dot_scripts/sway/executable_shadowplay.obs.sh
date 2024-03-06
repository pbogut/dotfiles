#!/usr/bin/env bash
#=================================================
# name:   mousescreenlock.sh
# author: Pawel Bogut <https://pbogut.me>
# date:   21/03/2022
# desc:   Locks mouse to game screen, usefull in
#         some games to prevent monitor switching
#=================================================

record_seconds=300
parts_to_keep=7
parts_to_merge=6

parts_path="/tmp/$USER/shadowplay"


cleanup() {
    # kill all processes whose parent is this process
    pkill -P $$
}

for sig in INT QUIT HUP TERM; do
  trap "
    cleanup
    trap - $sig EXIT
    kill -s $sig "'"$$"' "$sig"
done
trap cleanup EXIT



usage() {
  echo "Ussage: ${0##*/} [OPTIONS]"
  echo ""
  echo "Options:"
  echo "  -h, --help          display this help and exit"
  echo "  --screen-shot       take screenshot of the screen"
  echo "  --shadow-fullscreen {monitor}  start recording whole monitor"
  echo "  --save              save replay to file"
  echo "  --kill              kill screen recording"
}

action=""
while test $# -gt 0; do
  case "$1" in
  --kill)
    action="kill"
    shift
    ;;
  --screen-shot)
    action="screenshot"
    shift
    ;;
  --save | -s)
    action="save"
    shift
    ;;
  --shadow-fullscreen | -f)
    action="fullscreen"
    shift
    screen="$1"
    shift
    ;;
  --help | -h)
    usage
    exit 0
    ;;
  *)
    usage
    exit 1
    ;;
  esac
done

if [[ -z $action ]]; then
  usage
  exit 1
fi

if [[ $action == "screenshot" ]]; then
  notify-send -u low "Taking screenshot"
  newname="$(sway-prop -t | sed 's/[^A-Za-z0-9]/_/g')_$(date '+%Y-%m-%d_%H-%M-%S').png"
  swaymsg -t get_tree | jq -r '.. | select(.focused?) | .rect | "\(.x),\(.y) \(.width)x\(.height)"' | grim -g - "$HOME/Pictures/ShadowPlay/$newname"

  notify-send -u normal "Screen Shot saved $newname"
fi

if [[ $action == "kill" ]]; then
  pkill -x obs
fi

if [[ $action == "save" ]]; then
  if obs-cli replaybuffer -p 4334 --password "$OBS_CLI_PASSWORD" save; then
    notify-send -u low "Saved replay with OBS"
  else
    notify-send -u crit "Som-ting-wong with OBS"
  fi
fi

if [[ $action == "fullscreen" ]]; then
  notify-send -u low "Start Shadowing with OBS Replay Buffer"
  obs --startreplaybuffer --minimize-to-tray
fi

#!/usr/bin/env bash
#=================================================
# name:   mousescreenlock.sh
# author: Pawel Bogut <https://pbogut.me>
# date:   21/03/2022
# desc:   Locks mouse to game screen, usefull in
#         some games to prevent monitor switching
#=================================================

record_seconds=300

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

is_fullscreen() {
  xprop -id $1 | grep _NET_WM_STATE_FULLSCREEN >/dev/null 2>&1
  if [[ $? -eq 0 ]]; then
    echo 1
  else
    echo 0
  fi
}

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
  (for _ in {1..10}; do
    sleep 0.1s
    kill -9 $(ps -ef | grep 'wl-screenrec' | grep -v grep | awk '{print $2}') \
      >/dev/null 2>&1
  done) &

  pkill -RTMIN+15 -x waybar
  kill $(ps -ef | grep 'shadowplay.sh' | grep bash | grep -v grep | awk '{print $2}') \
    >/dev/null 2>&1
fi

if [[ $action == "save" ]]; then
  notify-send -u low "Saving replay..."
  kill -USR1 $(ps -ef | grep 'wl-screenrec' | grep -v grep | awk '{print $2}')
  kill -INT $(ps -ef | grep 'wl-screenrec' | grep -v grep | awk '{print $2}')
fi

if [[ $action == "fullscreen" ]]; then
  if [[ -z $screen ]]; then
    usage
    exit 1
  fi
  count=0
  notify-send -u low "Start Shadowing $screen"
  while :; do
    count=$(( count + 1 ))
    path="$HOME/Videos/ShadowPlay"
    # path="$HOME/Videos/ShadowPlay/$(echo $title | sed 's/[^A-Za-z0-9]/_/g')"

    (sleep 1s; pkill -RTMIN+15 -x waybar) &

    mkdir -p "$path"
    wl-screenrec \
      --audio --audio-device "$(pactl get-default-sink).monitor" \
      --history $record_seconds \
      -o "$screen" \
      -f "$path/capture.mp4"

    # newname="$(sway-prop -t | sed 's/[^A-Za-z0-9]/_/g')_$(date '+%Y-%m-%d_%H-%M-%S').mp4"
    newname="Replay_WL_$(date '+%Y-%m-%d_%H-%M-%S').mp4"

    if [[ $(du "$path/capture.mp4" | awk '{print $1}') -gt 1024 ]]; then
      # mv "$path/capture.mp4" "$path/$newname"
      # cut to video size (bug with audio being much longer than video)
      dur=$(ffprobe -v error -select_streams v:0 -show_entries stream=duration -of default=noprint_wrappers=1:nokey=1 "$path/capture.mp4" | awk '{print $1}')
      ffmpeg -ss 0 -t "$dur" -i "$path/capture.mp4" -c:a copy -c:v copy "$path/$newname"
      notify-send -u low "Save captured video $newname"
    else
      notify-send -u low "Nothing captured"
    fi

    if [[ $count -gt 100 ]] ;then
      exit 1
    fi
  done
fi

#!/usr/bin/env bash
#=================================================
# name:   mousescreenlock.sh
# author: Pawel Bogut <https://pbogut.me>
# date:   21/03/2022
# desc:   Locks mouse to game screen, usefull in
#         some games to prevent monitor switching
#=================================================

record_minutes=300
record_fps=60

usage() {
  echo "Ussage: ${0##*/} [OPTIONS]"
  echo ""
  echo "Options:"
  echo "  -h, --help          display this help and exit"
  echo "  --screen-shot       take screenshot of the screen"
  echo "  --wait-and-shadow   wait for the fullscreen window and start recording"
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
  --wait-and-shadow | -w)
    action="wait"
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
  newname="$(xtitle | sed 's/[^A-Za-z0-9]/_/g')_$(date '+%Y-%m-%d_%H-%M-%S').png"
  import -window $(xdotool getwindowfocus -f) "$HOME/Pictures/ShadowPlay/$newname"
  notify-send -u normal "Screen Shot saved $newname"
fi

if [[ $action == "kill" ]]; then
  kill -9 $(ps -ef | grep 'gpu-screen-recorder' | grep -v grep | awk '{print $2}') \
    >/dev/null 2>&1
  kill $(ps -ef | grep 'shadowplay.sh' | grep bash | grep -v grep | awk '{print $2}') \
    >/dev/null 2>&1
  kill -9 $(ps -ef | grep 'gpu-screen-recorder' | grep -v grep | awk '{print $2}') \
    >/dev/null 2>&1
fi

if [[ $action == "save" ]]; then
  notify-send -u low "Saving replay..."
  kill -USR1 $(ps -ef | grep 'gpu-screen-recorder' | grep -v grep | awk '{print $2}')
fi

if [[ $action == "fullscreen" ]]; then
  if [[ -z $screen ]]; then
    usage
    exit 1
  fi
  count=0
  while :; do
    count=$(( count + 1 ))
    notify-send -u low "Start Shadowing $screen"

    path="$HOME/Videos/ShadowPlay"
    # path="$HOME/Videos/ShadowPlay/$(echo $title | sed 's/[^A-Za-z0-9]/_/g')"

    mkdir -p "$path"

      gpu-screen-recorder -w "$screen" \
        -c mp4 -f $record_fps \
        -a "$(pactl get-default-sink).monitor" \
        -r $record_minutes \
        -o "$path"
    if [[ $count -gt 100 ]] ;then
      exit 1
    fi
  done
fi

if [[ $action == "wait" ]]; then
  i3-match \
    -Sm :evtype=window change=fullscreen_mode \
    -o container/window container/name |
    while read winid title; do
      if [[ $(is_fullscreen $winid) -eq 1 ]]; then
        while :; do
          notify-send -u low "Start Shadowing $title"

          path="$HOME/Videos/ShadowPlay/$(echo $title | sed 's/[^A-Za-z0-9]/_/g')"

          mkdir -p "$path"

          gpu-screen-recorder -w "$winid" \
            -s 1920x1080 \
            -c mp4 -f $record_fps \
            -a "$(pactl get-default-sink).monitor" \
            -r $record_minutes \
            -o "$path"
        done
      fi
    done
fi

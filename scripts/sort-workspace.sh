#!/usr/bin/env bash
#=================================================
# name:   sort-workspace
# author: Pawel Bogut <https://pbogut.me>
# date:   13/10/2021
#=================================================
current_ws=$(i3-msg -t get_workspaces | jq '.[] | select(.focused==true) | .name' -r)
xprop="$(xprop -id "$(xdpyinfo | grep -Eo 'window 0x[^,]+' | cut -d" " -f2)")"
wm_title=$(echo "$xprop" | grep '^WM_NAME' | sed 's,.* = "\(.*\)"$,\1,')
wm_class=$(echo "$xprop" | grep '^WM_CLASS' | sed 's,.* = "\(.*\)"$,\1,' | sed 's/", "/ /')


usage() {
  echo "Ussage: ${0##*/} [OPTIONS]"
  echo ""
  echo "Options:"
  echo "  -h, --help     display this help and exit"
}

move_top() {
  i3move --inside-distance 2 up
}

focus_toggle() {
  i3-msg focus mode_toggle
}

move() {
  new_ws="$1"
  if [[ "$current_ws" != "$new_ws" ]]; then
    i3-msg move window to workspace "$new_ws" > /dev/null
  fi
}

swich() {
  new_ws="$1"
  if [[ "$current_ws" != "$new_ws" ]]; then
    i3-msg workspace "$new_ws" > /dev/null
  fi
}

move_and_swich() {
  new_ws="$1"
  if [[ "$current_ws" != "$new_ws" ]]; then
    i3-msg move window to workspace "$new_ws" > /dev/null
    i3-msg workspace "$new_ws" > /dev/null
  fi
}

set_floating() {
  width=${1:-725px}
  height=${2:-430px}
  i3-msg "floating enable;" \
    "resize set width $width;" \
    "resize set height $height;" \
    "move position center;" \
    > /dev/null
}

get_current_ws() {
  i3-msg -t get_workspaces | jq -r '.[] | select(.focused == true).name'
}

while test $# -gt 0; do
  case "$1" in
    --extended|-e)
      extended=1
      shift
      ;;
    --title|--title=*|-t)
      if [[ $1 =~ --[a-z]+= ]]; then
        _val="${1//--title=/}"
        shift
      else
        _val="$2"
        shift; shift
      fi
      wm_title="$_val"
      ;;
    --help|-h)
      usage
      exit 0
      ;;
    *)
      shift
      ;;
  esac
done

ws_code="0:"
ws_term="0: term"
ws_comm="0:/ comm"
ws_media="0: media"
ws_browser="0: browser"
ws_db="0: db"
ws_dash="0: dash"
ws_rss="0: rss"
ws_vm="0: VM"
ws_lol="0: LoL"
ws_steam="0: steam"
ws_game="0: gaming"


if [[ $extended -eq 1 ]]; then
  found=1
  case  "$wm_class" in
    "qutebrowser qutebrowser")
      case "$wm_title" in
        *" - Invidious - "*)
          move_and_swich "$ws_media"
          ;;
        *)
          move_and_swich "$ws_browser"
          ;;
      esac
      ;;
    "urxvt URxvt"|"Alacritty Alacritty")
      case "$wm_title" in
        *~/Projects/*|*$HOME/Projects/*)
          project_name=${wm_title##*/}
          project_name=${project_name%% |t*} #filter tmux session out
          move_and_swich "$ws_code $project_name"
          ;;
        *)
          move_and_swich "$ws_term"
          ;;
      esac
      ;;
    *)
      found=0
      ;;
  esac
  [[ $found -eq 1 ]] && exit 0
fi

case  "$wm_class" in
  "gl mpv")
    move_and_swich "$ws_media"
    ;;
  "qutebrowser qutebrowser")
    move_and_swich "$ws_browser"
    ;;
  "Steam Steam"|"steam steam"|"heroic heroic")
    move_and_swich "$ws_game"
    ;;
  "obs obs")
    move_and_swich "$ws_game"
    ;;
  "csgo_linux64 csgo_linux64"|steam_app*|steam_proton*)
    move_and_swich "$ws_game"
    ;;
  "chiaki Chiaki")
    move_and_swich "$ws_game"
    ;;
  "leagueclient.exe leagueclient.exe")
    move_and_swich "$ws_lol"
    ;;
  "leagueclientux.exe leagueclientux.exe")
    move_and_swich "$ws_lol"
    ;;
  "league of legends.exe league of legends.exe")
    move_and_swich "$ws_lol"
    ;;
  "VBoxSDL VBoxSDL"|\
  "VirtualBox Manager VirtualBox Manager"|\
  "VirtualBox Machine VirtualBox Machine")
    move_and_swich "$ws_vm"
    ;;
  "rssguard RSS Guard")
    move_and_swich "$ws_rss"
    ;;
  "pavucontrol Pavucontrol")
    set_floating 800px 800px
    ;;
  "smplayer smplayer")
    move_and_swich "$ws_media"
    ;;
  "blueman-manager Blueman-manager")
    set_floating 800px 800px
    ;;
  "yad Yad")
    case "$wm_title" in
      "keepass show")
         move_top
         focus_toggle
        ;;
      *)
        exit 0
        ;;
    esac
    ;;
  "ferdi Ferdi")
    move_and_swich "$ws_comm"
    ;;
  "urxvt URxvt"|"Alacritty Alacritty")
    case "$wm_title" in
      QB_FILE_SELECTION)
        set_floating 1200px 800px
        ;;
      NVIM_FOR_QB)
        set_floating
        ;;
      EMAIL_MUTT)
        move_and_swich "$ws_comm"
        ;;
      *)
        current_ws=$(get_current_ws)
        if [[ "$current_ws" == "$ws_browser" ]]; then
          move_and_swich "$ws_term"
        fi
        exit 0
        ;;
    esac
    ;;
  *)
    exit 0
    ;;
esac

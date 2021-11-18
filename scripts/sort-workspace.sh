#!/usr/bin/env bash
#=================================================
# name:   sort-workspace
# author: Pawel Bogut <https://pbogut.me>
# date:   13/10/2021
#=================================================
current_ws=$(i3-msg -t get_workspaces | jq '.[] | select(.focused==true) | .name' -r)
xprop=$(xprop -id $(xdpyinfo | grep -Eo 'window 0x[^,]+' | cut -d" " -f2))
wm_title=$(echo "$xprop" | grep '^WM_NAME' | sed 's,.* = "\(.*\)"$,\1,')
wm_class=$(echo "$xprop" | grep '^WM_CLASS' | sed 's,.* = "\(.*\)"$,\1,' | sed 's/", "/ /')

date >> /tmp/wmsort
echo "TITLE: $wm_title" >> /tmp/wmsort
echo "CLASS: $wm_class" >> /tmp/wmsort

usage() {
  echo "Ussage: ${0##*/} [OPTIONS]"
  echo ""
  echo "Options:"
  echo "  -h, --help     display this help and exit"
}

move_top() {
  i3-msg move down 50ppt > /dev/null
  i3-msg move down 5ppt > /dev/null
  i3-msg move down 5ppt > /dev/null
  i3-msg move down 5ppt > /dev/null
  i3-msg move down 5ppt > /dev/null
  i3-msg move down 5ppt > /dev/null
  i3-msg move up 95ppt > /dev/null
}

focus_toggle() {
  i3-msg focus mode_toggle
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

if [[ $extended -eq 1 ]]; then
  found=1
  case  "$wm_class" in
    "qutebrowser qutebrowser")
      move_and_swich "$ws_browser"
      ;;
    "urxvt URxvt"|"Alacritty Alacritty")
      case "$wm_title" in
        *~/Projects/*|*$HOME/Projects/*)
          project_name=${wm_title##*/}
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
        exit 0
        ;;
    esac
    ;;
  *)
    exit 0
    ;;
esac

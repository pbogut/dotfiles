#!/usr/bin/env bash
#=================================================
# name:   sort-workspace
# author: Pawel Bogut <https://pbogut.me>
# date:   13/10/2021
#=================================================
current_ws=$(i3-msg -t get_workspaces | jq '.[] | select(.focused==true) | .name' -r)
prop="$(sway-prop)"
wm_title=$(echo "$prop" | jq '.title' -r)
wm_class=$(echo "$prop" | jq '.instance + " " + .class' -r)
wm_app_id=$(echo "$prop" | jq '.app_id' -r)

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
    swaymsg move window to workspace "$new_ws" > /dev/null
  fi
}

swich() {
  new_ws="$1"
  if [[ "$current_ws" != "$new_ws" ]]; then
    swaymsg workspace "$new_ws" > /dev/null
  fi
}

move_and_swich() {
  new_ws="$1"
  if [[ "$current_ws" != "$new_ws" ]]; then
    swaymsg move window to workspace "$new_ws" > /dev/null
    swaymsg workspace "$new_ws" > /dev/null
  fi
}

set_fullscreen() {
  swaymsg fullscreen enable > /dev/null
}

unset_floating() {
  swaymsg "floating disable;"
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

ws_browser="1:  browser"
ws_term="2:  term"
ws_comm="3: / comm"
ws_code="4:  code"
ws_media="5:  media"
ws_work="6:  work"
ws_db=" db"
ws_dash="9:  dash"
ws_rss=" rss"
ws_vm=" VM"
ws_steam="8:  steam"
ws_game="7:  gaming"
ws_3d=" 3d"

workspaces=(
  "$ws_browser"
  "$ws_term"
  "$ws_comm"
  "$ws_code"
  "$ws_media"
  "$ws_work"
  "$ws_db"
  "$ws_dash"
  "$ws_rss"
  "$ws_vm"
  "$ws_steam"
  "$ws_game"
  "$ws_3d"
)


if [[ $extended -eq 1 ]]; then
  found=1
  case  "$wm_app_id" in
    "Alacritty"|"foot"|"org.wezfurlong.wezterm")
      case "$wm_title" in
        *[*"  "*]*)
          project_name=${wm_title##*/}
          project_name=${project_name%% |t*} #filter tmux session out
          move_and_swich "$ws_code"
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
case  "$wm_app_id" in
  "com.discordapp.Discord")
    move_and_swich "$ws_comm"
    ;;
  "org.wezterm.floating")
    swaymsg "resize set width 1200px; resize set height 700px"
    ;;
  "Alacritty"|"foot"|"org.wezfurlong.wezterm")
      case "$wm_title" in
        *"  "*)
          move_and_swich "$ws_code"
          ;;
        *)
          current_ws=$(get_current_ws)
          for ws in "${workspaces[@]}"; do
            if [[ "$current_ws" == "$ws" ]]; then
              move_and_swich "$ws_term"
            fi
          done
          exit 0
          ;;
      esac
    ;;
  "org.gnome.Hamster.GUI")
    move_and_swich "$ws_dash"
    ;;
  "discord")
    move_and_swich "$ws_comm"
    ;;
  "chrome-www.deezer.com__en_-Default")
    # set_floating 1600px 900px
    move_and_swich "$ws_media"
    ;;
  *"-www.youtube.com_"*|*"-rumble.com_"*)
    move_and_swich "$ws_media"
    ;;
  "com.gitlab.newsflash"|"io.gitlab.news_flash.NewsFlash")
    move_and_swich "$ws_rss"
    ;;
  "vivaldi-"*)
    case "$wm_title" in
      "Bitwarden - Vivaldi")
        sleep 0.1s
        set_floating 400px 800px
        ;;
      "Developer Tools - Vivaldi"*|"DevTools - "*|"DevToolsApp"|"DevTools")
        swaymsg "move right; resize set width 680px"
        ;;
      *)
        case  "$wm_app_id" in
          "vivaldi-agimnkijcaahngcdmfeangaknmldooml-Default")
            move_and_swich "$ws_media"
            ;;
          "vivaldi-work")
            move_and_swich "$ws_work"
            ;;
          "vivaldi-personal")
            move_and_swich "$ws_browser"
            ;;
        esac
        ;;
    esac
    ;;
  "org.qutebrowser.mediabrowser")
    move_and_swich "$ws_media"
    ;;
  "zen-work"|"chromium-work"|"firefox-work"|"org.qutebrowser.workbrowser")
    move_and_swich "$ws_work"
    ;;
  "zen-personal"|"chromium-personal"|"firefox-personal"|"org.qutebrowser.qutebrowser")
    move_and_swich "$ws_browser"
    ;;
  "mpv")
    move_and_swich "$ws_media"
    ;;
  "gamescope")
    move_and_swich "$ws_game"
    set_fullscreen
    ;;
  "org.openscad.openscad")
    move_and_swich "$ws_3d"
    ;;
  "ferdium")
    move_and_swich "$ws_comm"
    ;;
esac
case  "$wm_class" in
  "www.youtube.com__"*)
    move_and_swich "$ws_media"
    ;;
  "freetube FreeTube")
    move_and_swich "$ws_media"
    ;;
  "www.deezer.com__en Chromium")
    set_floating 1600px 900px
    ;;
  *".exe")
    move_and_swich "$ws_game"
    ;;
  "prusa-slicer PrusaSlicer")
    move_and_swich "$ws_3d"
    ;;
  "openscad OpenSCAD")
    move_and_swich "$ws_3d"
    ;;
  "Steam Steam"|"steam steam"|"heroic heroic"|"steamwebhelper steamwebhelper"|"steamwebhelper steam")
    move_and_swich "$ws_steam"
    ;;
  "obs obs"|\
  "Liftoff.x86_64 Liftoff.x86_64"|\
  "chiaki Chiaki"|\
  "csgo_linux64 csgo_linux64"|"cs2 cs2"|\
  "gamescope gamescope"|\
  "geforce now GeForce NOW"|\
  "steam_app"*|"steam_proton"*)
    move_and_swich "$ws_game"
    unset_floating
    set_fullscreen
    ;;
  "VBoxSDL VBoxSDL"|\
  "VirtualBox Manager VirtualBox Manager"|\
  "VirtualBox Machine VirtualBox Machine")
    move_and_swich "$ws_vm"
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
  "ferdi Ferdi"|"signal Signal"|"ferdium Ferdium")
    move_and_swich "$ws_comm"
    ;;
  "urxvt URxvt"|"Alacritty Alacritty"|"foot foot")
    case "$wm_title" in
      FLOATING_WINDOW)
        set_floating 800px 600px
        ;;
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

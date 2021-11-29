#!/bin/bash
hostname=$(hostname)
set_walpaper() {
  feh --randomize --bg-fill ~/Pictures/wallpaper
}
if [ "$hostname" == "redeye" ]; then # pc
  hdmi0=$(xrandr | grep HDMI-0)
  stnr="0"
  if [[ $hdmi0 == "" ]]; then
    stnr="1"
  fi
  xrandr --output VGA-$stnr --off --output DVI-D-$stnr --mode 1920x1080 --pos 0x0 --rotate normal --output HDMI-$stnr --primary --mode 1920x1080 --pos 1920x0 --rotate normal

  set_walpaper
else
  set_walpaper
fi
xset s off -dpms
xset r rate 250 15
source ~/.scripts/autostart.sh

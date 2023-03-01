#!/bin/bash
hostname=$(hostname)
set_walpaper() {
  feh --randomize --bg-fill ~/Pictures/wallpaper
}
if [ "$hostname" == "redeye" ]; then # pc
  xrandr \
    --output HDMI-0 --mode 1920x1080 --pos 3840x0 --rotate normal \
    --output DP-3 --mode 1920x1080 --pos 0x0 --rotate normal \
    --output DP-4 --primary --mode 1920x1080 --refresh 144 --pos 1920x0 --rotate normal \
    --output DP-1 --off --output DP-2 --off --output DP-4 --off --output DP-5 --off

  set_walpaper
else
  set_walpaper
fi
xset s off -dpms
xset r rate 250 15

source ~/.scripts/autostart.sh

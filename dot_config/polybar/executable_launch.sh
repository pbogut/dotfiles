#!/bin/bash
#=================================================
# name:   launch.sh
# author: Pawel Bogut <https://pbogut.me>
# date:   22/12/2020
#=================================================

killall -q polybar

# Terminate already running bar instances
# If all your bars have ipc enabled, you can also use
# polybar-msg cmd quit

hostname=$(hostname)

if [[ $hostname == "silverspoon" ]]; then
  echo "---" | tee -a /tmp/polybar1.log
  MONITOR=eDP1 polybar silverspoon 2>&1 | tee -a /tmp/polybar1.log & disown
elif [[ $hostname = "redeye" ]]; then
  echo "---" | tee -a /tmp/polybar1.log /tmp/polybar2.log
  # MONITOR=HDMI-0 polybar primary   2>&1 | tee -a /tmp/polybar1.log & disown
  # MONITOR=DP-4   polybar secondary 2>&1 | tee -a /tmp/polybar2.log & disown
  # MONITOR=DP-3   polybar secondary 2>&1 | tee -a /tmp/polybar3.log & disown
  MONITOR=HDMI-A-0 polybar primary   2>&1 | tee -a /tmp/polybar1.log & disown
  MONITOR=DisplayPort-0   polybar secondary 2>&1 | tee -a /tmp/polybar2.log & disown
  MONITOR=DisplayPort-1   polybar secondary 2>&1 | tee -a /tmp/polybar3.log & disown
else
  echo "---" | tee -a /tmp/polybar1.log
  primary=$(polybar -m | grep '(primary)' | awk '{gsub(/:$/, "", $1); print $1}')
  MONITOR=$primary polybar primary 2>&1 | tee -a /tmp/polybar1.log & disown
fi

echo "Bars launched..."

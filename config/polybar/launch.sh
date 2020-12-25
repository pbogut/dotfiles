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



screens=$(polybar -m | wc -l)
primary=$(polybar -m | grep '(primary)' | awk '{gsub(/:$/, "", $1); print $1}')

if [[ $screens -eq 2 ]]; then
  echo "---" | tee -a /tmp/polybar1.log /tmp/polybar2.log
  secondary=$(polybar -m | grep -v '(primary)' | awk '{gsub(/:$/, "", $1); print $1}' | head -n1)

  MONITOR=$primary    polybar primary     2>&1 | tee -a /tmp/polybar1.log & disown
  MONITOR=$secondary  polybar secondary   2>&1 | tee -a /tmp/polybar2.log & disown
else
  echo "---" | tee -a /tmp/polybar1.log
  MONITOR=$primary    polybar primary     2>&1 | tee -a /tmp/polybar1.log & disown
fi

echo "Bars launched..."

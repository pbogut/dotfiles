#!/usr/bin/env bash
#=================================================
# name:   picom
# author: Pawel Bogut <https://pbogut.me>
# date:   28/02/2022
#=================================================
usage() {
  echo "Ussage: ${0##*/} [OPTIONS]"
  echo ""
  echo "Options:"
  echo "  -h, --help     display this help and exit"
  echo "  -r, --run      run app within gamemode"
  echo "  -s, --start    start gamemode"
  echo "  -e, --end      end gamemode"
  echo "  -w, --watch    start watcher for steam games"
}

nvidia=false

while test $# -gt 0; do
  case "$1" in
    --run|-r)
      action=run
      shift
      # shellcheck disable=SC2068
      $0 --start && $@ && $0 --end
      exit 0
      ;;
    --end|-e)
      action=end
      shift
      ;;
    --start|-s)
      action=start
      shift
      ;;
    --watch|-w)
      action=watch
      shift
      ;;
    --help|-h)
      usage
      exit 0
      ;;
    *)
      usage
      exit 1
      ;;
  esac
done

host=$(hostname)

if [[ $action == "start" ]]; then
  notify-send "GameMode started"
  killall picom
  pkill -USR1 '^redshift$'

  # lock mouse to game screen
  at now <<< "DISPLAY=$DISPLAY ~/.scripts/mousescreenlock.sh" > /dev/null 2>&1
  # shadow play for selected games
  at now <<< "DISPLAY=$DISPLAY ~/.scripts/shadowplay.sh --shadow-fullscreen DisplayPort-0" > /dev/null 2>&1

  if $nvidia; then
    nvidia-settings -a GpuPowerMizerMode=1 > /dev/null 2>&1
  fi

  # echo performance | sudo tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor
  # for sudouers rule to work
  find /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor | while read -r line; do
    echo performance | sudo tee "$line" > /dev/null 2>&1
  done
elif [[ $action == "end" ]]; then
  notify-send "GameMode stopped"
  if [[ $host == "redeye" ]]; then
    picom -b --xrender-sync-fence
    dualsensectl power-off
  elif [[ $host == "silverspoon" ]]; then
    picom -b --inactive-dim 0 -i 1
  fi
  pkill -USR1 '^redshift$'

  # stop mouselock
  # shellcheck disable=SC2046
  kill $(pgrep -f 'mousescreenlock.sh')
  # stop shadowing
  ~/.scripts/shadowplay.sh --kill

  if $nvidia; then
    nvidia-settings -a GpuPowerMizerMode=2 > /dev/null 2>&1
  fi

  find /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor | while read -r line; do
    echo schedutil | sudo tee "$line" > /dev/null 2>&1
  done
elif [[ $action == "watch" ]]; then
  was_on=0
  while :; do
    is_on=$(pgrep -f '[Ss]team/.*/reaper')
    if [[ -n $is_on && $was_on -eq 0 ]]; then
      was_on=1
      $0 --start
    fi
    if [[ -z $is_on && $was_on -eq 1 ]]; then
      was_on=0
      $0 --end
    fi
    sleep 30s;
  done
else
  usage
  exit 1
fi

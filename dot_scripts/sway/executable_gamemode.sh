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

cleanup() {
    echo "Termination signal received. Cleaning up..."
    # Kill all child processes
    pkill -P $$
    exit 0
}
# Set up trap to catch termination signal
trap cleanup SIGTERM

if [[ $action == "start" ]]; then
  notify-send "GameMode started"
  killall wlsunset

  # lock mouse on game screen
  #notify-send -t 2500 -u low "Lock mouse on screen"
  #sway 'output DP-1 pos 1920 2000'
  swaymsg 'seat * hide_cursor when-typing disable'

  # shadow play for selected games
  at now <<< "$HOME/.scripts/sway/shadowplay.sh --shadow-fullscreen DP-1" > /dev/null 2>&1

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
  at now <<< "wlsunset -l 50 -L 17" > /dev/null 2>&1

  # release mouse from game screen
  swaymsg 'seat * hide_cursor when-typing enable'
  # stop shadowing
  ~/.scripts/sway/shadowplay.sh --kill

  if $nvidia; then
    nvidia-settings -a GpuPowerMizerMode=2 > /dev/null 2>&1
  fi

  find /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor | while read -r line; do
    echo schedutil | sudo tee "$line" > /dev/null 2>&1
  done
elif [[ $action == "watch" ]]; then
  was_on=0
  sway-prop -l | tee -a /tmp/swayprop | while read -r props; do
    class=$(jq -r '.class' <<< "$props")
    id=$(jq -r '.app_id' <<< "$props")
    match=$class
    if [[ $class == "null" ]]; then
      match=$id
    fi
    case "$match" in
      steam_app_*|gamescope|csgo_linux64|cs2|steamwebhelper.exe|steam.exe)
        if [[ $was_on -eq 0 ]]; then
          was_on=1
          $0 --start
        fi
        ;;
      *)
        if ! pgrep -f '[Ss]team/.*/reaper' && ! pgrep -f '[Ss]team/.*/reaper.exe' && [[ $was_on -eq 1 ]]; then
          was_on=0
          $0 --end
        fi
        ;;
    esac
  done
else
  usage
  exit 1
fi


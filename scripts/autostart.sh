#!/bin/bash
#super awesome capslock key
host_name=$(hostname -s)
script=$(readlink -f "$0")
scriptpath=$(dirname "$script")

killall sway-prop -9

function demonize() {
  pid="/tmp/__$(id -un)__$1.pid"
  # if no pid file or no process
  if [ ! -f "$pid" ] || ! kill -0 $(cat $pid) 2>/dev/null; then
    # $2 >/dev/null 2>&1 &
    $2 &
    echo $! >$pid
  fi
}

function rerun() {
  # killall "$1" >/dev/null 2>&1
  kill $(pgrep -f "$2")
  $2 >/dev/null 2>&1 &
}

# numlock
numlockx on

# daemons
rerun copyq copyq
demonize nextcloud "nextcloud"
demonize wlsunset "wlsunset -l 50 -L 17"
demonize nm-applet nm-applet
demonize dunst dunst
demonize udisksvm "udisksvm -a"
demonize memwatch ~/.scripts/memwatch.sh
demonize mailsgoweb ~/.scripts/mailsgoweb.sh
demonize kdeconnect kdeconnect-indicator
at now + 10 minutes <<< "nextcloud --background"
# demonize nextcloud "nextcloud --background"

# sepcific for the computer
if [[ -f "$HOME/.autostart.$host_name.sh" ]]; then
  # shellcheck disable=1090
  source "$HOME/.autostart.$host_name.sh"
fi
# just local one, not versioned
if [[ -f "$HOME/.autostart.local.sh" ]]; then
  # shellcheck disable=1091
  source "$HOME/.autostart.local.sh"
fi

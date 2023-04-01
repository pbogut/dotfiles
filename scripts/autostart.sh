#!/bin/bash
#super awesome capslock key
host_name=$(hostname -s)
script=$(readlink -f "$0")
scriptpath=$(dirname "$script")

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
  killall $1 >/dev/null 2>&1
  $2 >/dev/null 2>&1 &
}

# numlock
numlockx on

# daemons
rerun copyq copyq
demonize nextcloud nextcloud
demonize conky conky
demonize geoclue /usr/lib/geoclue-2.0/demos/agent
demonize redshift redshift-gtk
demonize textaid "perl $scriptpath/edit-server.pl"
demonize nm-applet nm-applet
demonize dunst dunst
demonize udisksvm "udisksvm -a"
demonize memwatch ~/.scripts/memwatch.sh
demonize mailsgoweb ~/.scripts/mailsgoweb.sh
demonize kdeconnect kdeconnect-indicator

# sepcific for the computer
if [[ -f "$HOME/.$host_name.autostart.sh" ]]; then
  source "$HOME/.$host_name.autostart.sh"
fi
# just local one, not versioned
if [[ -f "$HOME/.autostart.local.sh" ]]; then
  source "$HOME/.autostart.local.sh"
fi

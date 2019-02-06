#!/bin/bash
#super awesome capslock key
setxkbmap -option 'caps:ctrl_modifier'
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
# make use of the useless capslock
killall xcape -9 >/dev/null 2>&1
# only if run with xcape option (its not playing nicely with my ergodox)
if [[ $1 == "--xcape" ]]; then
  xcape -e 'Caps_Lock=Escape'
  xcape -e 'Control_L=Escape'
  xcape -e 'Shift_L=parenleft'
  xcape -e 'Shift_R=parenright'
fi

# daemons
#rerun insync "insync start"
# rerun anamnesis "anamnesis --start"
rerun copyq
rerun compton "compton -b --xrender-sync-fence --xrender-sync"
rerun TogglDesktop "toggldesktop -b"
#rerun megasync megasync

demonize geoclue /usr/lib/geoclue-2.0/demos/agent
demonize redshift redshift-gtk
demonize textaid "perl $scriptpath/edit-server.pl"
#demonize rescuetime rescuetime
demonize nm-applet nm-applet
demonize dunst dunst
demonize udisksvm "udisksvm -a"
#demonize mopidy "mopidy -o mpd/port=${MOPIDY_PORT:-6600}"
demonize pomodoro "i3-gnome-pomodoro daemon"
demonize memwatch ~/.scripts/memwatch.sh
demonize mailsgoweb ~/.scripts/mailsgoweb.sh

# sepcific for the computer
if [[ -f "$HOME/.$host_name.autostart.sh" ]]; then
  source "$HOME/.$host_name.autostart.sh"
fi
# just local one, not versioned
if [[ -f "$HOME/.autostart.local.sh" ]]; then
  source "$HOME/.autostart.local.sh"
fi

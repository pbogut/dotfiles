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
    $2 >/dev/null 2>&1 &
    echo $! >$pid
  fi
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
mails-go-web -r 'notmuch search --output=files id:%s' >/dev/null 2>&1 &
anamnesis --start >/dev/null 2>&1
insync start >/dev/null 2>&1
compton -b --xrender-sync-fence --xrender-sync
demonize redshift 'redshift-gtk'
demonize textaid "perl $scriptpath/edit-server.pl"
demonize rescuetime rescuetime
demonize nm-applet nm-applet
demonize dunst dunst
demonize udisksvm "udisksvm -a"
demonize mopidy "mopidy -o mpd/port=${MOPIDY_PORT:-6600}"
demonize gajim gajim-forever

# sepcific for the computer
if [[ -f "$HOME/.$host_name.autostart.sh" ]]; then
  source "$HOME/.$host_name.autostart.sh"
fi

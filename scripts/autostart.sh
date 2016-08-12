#!/bin/bash
#super awesome capslock key
setxkbmap -option 'caps:ctrl_modifier'
host_name=`hostname -s`
killall xcape -9 > /dev/null 2>&1
xcape -e 'Caps_Lock=Escape'
# anamnesis clipboard daemon
anamnesis --start 2>&1 > /dev/null
# custom daemons
script=$(readlink -f "$0")
scriptpath=$(dirname "$script")
<<<<<<< HEAD
textaid_pid=/tmp/textaid.pid
if [ -f "$textaid_pid" ] && kill -0 `cat $textaid_pid` 2>/dev/null; then
    echo 'ekhm....' > /dev/null
else
    perl "$scriptpath/edit-server.pl" &
    echo $! > $textaid_pid
fi
mopidy_pid=/tmp/mopidy.pid
if [ -f "$mopidy_pid" ] && kill -0 `cat $mopidy_pid` 2>/dev/null; then
    echo 'ekhm....' > /dev/null
else
    mopidy -q &
    echo $! > $mopidy_pid
fi
i3_focus_last_pid=/tmp/i3_focus_last.pid
if [ -f "$i3_focus_last_pid" ] && kill -0 `cat $i3_focus_last_pid` 2>/dev/null; then
    echo 'ekhm....' > /dev/null
else
    i3-focus-last.py &
    echo $! > $i3_focus_last_pid
fi
=======
>>>>>>> 755b06b6e87927e4276e5f96a6d875c10936fe57

function demonize {
    pid="/tmp/__$1.pid"
    # if no pid file or no process
    if [ ! -f "$pid" ] || ! kill -0 `cat $pid` 2>/dev/null; then
        $2 > /dev/null 2>&1 &
        echo $! > $pid
    fi
}

demonize redshift 'redshift-gtk'
demonize textaid "perl $scriptpath/edit-server.pl"
demonize mopidy mopidy
demonize rescuetime rescuetime

# sepcific for the computer
if [ "$host_name" == "darkbox" ]; then # pc at work
    demonize davmail davmail
fi

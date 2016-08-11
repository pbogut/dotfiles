#super awesome capslock key
setxkbmap -option 'caps:ctrl_modifier'
host_name=`hostname -s`
killall xcape -9 > /dev/null 2>&1
xcape -e 'Caps_Lock=Escape'
#chrome textaid extention server
# anamnesis clipboard daemon
anamnesis --start 2>&1 > /dev/null
# custom daemons
script=$(readlink -f "$0")
scriptpath=$(dirname "$script")
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

rescue_time_pid=/tmp/rescue_time.pid
if [ -f "$rescue_time_pid" ] && kill -0 `cat $rescue_time_pid` 2>/dev/null; then
    echo 'ekhm....' > /dev/null
else
    rescuetime &
    echo $! > $rescue_time_pid
fi
# sepcific for the computer
if [ "$host_name" == "darkbox" ]; then # pc at work
    dav_mail_pid=/tmp/dav_mail.pid
    if [ -f "$dav_mail_pid" ] && kill -0 `cat $dav_mail_pid` 2>/dev/null; then
        echo 'ekhm....' > /dev/null
    else
        davmail &
        echo $! > $dav_mail_pid
    fi
fi

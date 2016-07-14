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
    mopidy &
    echo $! > $mopidy_pid
fi

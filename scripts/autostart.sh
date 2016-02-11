#super awesome capslock key
setxkbmap -option 'caps:ctrl_modifier'
xcape -e 'Caps_Lock=Escape'
#chrome textaid extention server
script=$(readlink -f "$0")
scriptpath=$(dirname "$script")
pidfile=/tmp/textaid.pid
if [ -f "$pidfile" ] && kill -0 `cat $pidfile` 2>/dev/null; then
    echo 'ekhm....' > /dev/null
else
    perl "$scriptpath/edit-server.pl" &
    echo $! > $pidfile
fi

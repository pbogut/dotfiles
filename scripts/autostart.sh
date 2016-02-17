#super awesome capslock key
setxkbmap -option 'caps:ctrl_modifier'
host_name=`hostname -s`
if [ $DISPLAY = ":0.0" ] || [ $DISPLAY = ":0" ]; then
    if [ -f $HOME/conf/xkb/$host_name ]; then
        xkbcomp -I$HOME/.xkb $HOME/.xkb/$host_name.xkb $DISPLAY
    else
        xkbcomp -I$HOME/.xkb $HOME/.xkb/colemak_pl.xkb $DISPLAY
    fi
fi
killall xcape -9 > /dev/null 2>&1
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

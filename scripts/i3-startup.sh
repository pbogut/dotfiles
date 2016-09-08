#!/bin/bash
#xrandr --output HDMI-1 --mode 1920x1080 --pos 1920x0 --output HDMI-2 --primary --mode 1920x1080 --pos 0x0
#xrandr --output eDP1 --mode 1368x768 --pos 1920x0 --output HDMI1 --primary --mode 1920x1080 --pos 0x0
hostname=`hostname`
set_walpaper () {
    # mplayer -rootwin -ao null -noconsolecontrols  -fs -cookies -cookies-file /tmp/cookie.txt $(youtube-dl -g --cookies /tmp/cookie.txt "http://www.youtube.com/watch?v=f7kp4w43hag") > /dev/null 2>&1 &
    feh --randomize --bg-fill  ~/Pictures/wallpaper
}
if [ "$hostname" == "v3engine" ]; then # my laptop
    (   sleep 3
        xrandr --output HDMI1 --primary --mode 1920x1080 --pos 0x0 --output eDP1 --mode 1368x768 --pos 1920x125
        i3-msg restart
        set_walpaper
    )  &
elif [ "$hostname" == "darkbox" ]; then # pc at work
    xrandr --output HDMI-1 --mode 1920x1080 --pos 1920x0 --output HDMI-2 --primary --mode 1920x1080 --pos 0x0
    set_walpaper
else
    set_walpaper
fi
source ~/.scripts/autostart.sh

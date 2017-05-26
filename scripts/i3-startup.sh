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
        xrandr --newmode "1408x790"  91.09  1408 1480 1632 1856  790 791 794 818  -HSync +Vsync
        xrandr --addmode eDP-1 "1408x790"
        xrandr --output HDMI-1 --primary --mode 1920x1080 --pos 0x0 --output eDP-1 --mode 1408x790 --pos 1920x290
        # xrandr --newmode "1368x768" 85.86  1368 1440 1584 1800  768 769 772 795  -HSync +Vsync
        # xrandr --addmode eDP-1 "1368x768"
        # xrandr --output HDMI1 --primary --mode 1920x1080 --pos 0x0 --output eDP1 --mode 1368x768 --pos 1920x312
        # xrandr --output HDMI-1 --primary --mode 1920x1080 --pos 0x0 --output eDP-1 --mode 1920x1080 --pos 1920x0
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

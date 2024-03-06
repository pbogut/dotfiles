#!/bin/bash
hostname=$(hostname)
if [ "$hostname" == "redeye" ]; then # pc
    echo "Setting up redeye" >> /tmp/autostart.log
    sway output DP-2 pos 0 0 mode 1920x1080@60Hz
    sway output DP-1 pos 1920 0 mode 1920x1080@144Hz
    sway output HDMI-A-1 pos 3840 0 mode 1920x1080@60Hz
    echo "Setting primary monitor" >> /tmp/autostart.log

    xrandr --output DP-1 --primary
fi

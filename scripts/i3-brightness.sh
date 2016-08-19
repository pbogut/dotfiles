#!/bin/bash
brightness=`cat /sys/class/backlight/intel_backlight/brightness`
max_brightness=`cat /sys/class/backlight/intel_backlight/max_brightness`
if [ "$1" == "up" ] && (($brightness < $max_brightness)); then
    brightness=`expr $brightness + 100`
    echo "echo $brightness > /sys/class/backlight/intel_backlight/brightness" | sudo bash
fi
if [ "$1" == "down" ] && (($brightness > 0)); then
    brightness=`expr $brightness - 100`
    echo "echo $brightness > /sys/class/backlight/intel_backlight/brightness" | sudo bash
fi
echo "Brightness: `expr 100 \* $brightness / $max_brightness`%"

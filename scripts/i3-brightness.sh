#!/bin/bash
current_brightness=`cat /sys/class/backlight/intel_backlight/brightness`
max_brightness=`cat /sys/class/backlight/intel_backlight/max_brightness`
if [ "$1" == "up" ] && (($current_brightness < $max_brightness)); then
    brightness=`expr $current_brightness + 100`
    echo "echo $brightness > /sys/class/backlight/intel_backlight/brightness" | sudo bash
fi
if [ "$1" == "down" ] && (($current_brightness > 0)); then
    brightness=`expr $current_brightness - 100`
    echo "echo $brightness > /sys/class/backlight/intel_backlight/brightness" | sudo bash
fi

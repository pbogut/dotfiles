#!/bin/bash

bing="www.bing.com"
img=`curl www.bing.com | grep 'g_img={url:' | sed 's/.*g_img={url: "\([^"]*\)".*/\1/'`

saveDir="$HOME/Pictures/wallpaper/"

mkdir -p $saveDir

desiredPicURL="$bing$img"

# Set picName to the desired picName
picName=${desiredPicURL##*/}
# Download the Bing pic of the day at desired resolution
curl -s -o $saveDir$picName $desiredPicURL

# set as wallpaper using feh
feh --bg-fill $saveDir$picName

# Remove pictures older than 30 days
#find $saveDir -atime 30 -delete

# Exit the script
exit

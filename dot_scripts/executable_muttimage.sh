#! /bin/sh
#### Determine size of Terminal
height=`stty  size | awk 'BEGIN {FS = " "} {print $1;}'`
width=`stty  size | awk 'BEGIN {FS = " "} {print $2;}'`
px_height=$((height*15))
px_width=$((width*7))
### Convert image size so it always keep ratio and dont overflow
convert $1 -resize $((px_width))x$((px_height))\> -background darkslategrey -gravity center -extent $((px_width))x$((px_height)) "$1.resized" > /dev/null 2>&1 &&
### Display Image / offset with mutt bar
echo -e "2;3;\n0;1;270;20;$px_width;$px_height;0;0;0;0;$1.resized\n4;\n3;" |  /usr/lib/w3m/w3mimgdisplay &

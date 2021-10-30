#!/bin/bash
#=================================================
# name:   show-image
# author: Pawel Bogut <https://pbogut.me>
# date:   03/01/2021
#=================================================
# file=$1
# column_width=4
# width=$(($COLUMNS * $column_width))
# echo $width
# echo -e "\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n"
# # echo -e "2;3;\n0;1;0;100;0;0;0;0;0;0;$file\n4;\n3;" | /usr/lib/w3m/w3mimgdisplay
# # echo -e "2;3;\n0;1;0;100;0;0;0;0;0;0;$file\n4;\n3;" | /usr/lib/w3m/w3mimgdisplay
# # echo -e "2;3;\n0;1;0;100;0;0;0;0;0;0;$file\n4;\n3;" | /usr/lib/w3m/w3mimgdisplay
# echo -e "6;\n2;3;\n0;1;$width;10;$width;0;0;0;0;0;$file\n4;\n3;" | /usr/lib/w3m/w3mimgdisplay


test -z "$1" && exit

W3MIMGDISPLAY="/usr/lib/w3m/w3mimgdisplay"
FILENAME=$1
FONTH=14 # Size of one terminal row
FONTW=8  # Size of one terminal column
COLUMNS=`tput cols`
LINES=`tput lines`

col_to_draw=$(($COLUMNS / 2))
LINES=`tput lines`

read width height <<< `echo -e "5;$FILENAME" | $W3MIMGDISPLAY`

max_width=$(($FONTW * $col_to_draw))
max_height=$(($FONTH * $(($LINES - 2)))) # substract one line for prompt

if test $width -gt $max_width 2>/dev/null; then
height=$(($height * $max_width / $width))
width=$max_width
fi
if test $height -gt $max_height 2>/dev/null; then
width=$(($width * $max_height / $height))
height=$max_height
fi

w3m_command="0;1;$(($max_width + 12));15;$width;$height;;;;;$FILENAME\n4;\n3;"

# tput cup $(($height / $FONTH)) 0
echo -e $w3m_command|$W3MIMGDISPLAY

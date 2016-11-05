#!/bin/bash
log=/tmp/xranger.log
path=${1#file://}

if [ -d "$path" ]
then
     urxvt -e ranger "$path" &>> $log
else
     urxvt -e ranger --selectfile="$path" &>> $log
fi

#!/usr/bin/env bash
#=================================================
# name:   compress-video
# author: Pawel Bogut <https://pbogut.me>
# date:   29/12/2021
#=================================================
input="$1"
output="$2"

#crf=28 # bit lower
crf=25 # higher

ffmpeg -i "$input" -vcodec libx265 -crf "$crf" -c:a copy -c:s copy "$output"

#!/bin/bash
#=================================================
# name:   mpd-current-song.sh
# author: Pawel Bogut <http://pbogut.me>
# date:   09/11/2017
#=================================================

(while :; do
  # mpc="mpc -p ${MOPIDY_PORT:-6600}"
  mpc="mpc"
  $mpc current \
    | sed 's/"/'"'"'/g' \
    | sed 's/\(.*\)/{"full_text": "'"`$mpc | grep paused | sed 's/.*/ /g'`"'\1"}/g'

  $mpc idleloop player \
    | while read x;do
      $mpc current \
        | sed 's/"/'"'"'/g' \
        | sed 's/\(.*\)/{"full_text": "'"`$mpc | grep paused | sed 's/.*/ /g'`"'\1"}/g'
    done
  sleep 1s
done) &

sleep 3s;

while read line; do
  mpc="mpc -p ${MOPIDY_PORT:-6600}"
  $mpc toggle > /dev/null
  $mpc current \
    | sed 's/"/'"'"'/g' \
    | sed 's/\(.*\)/{"full_text": "'"`$mpc | grep paused | sed 's/.*/ /g'`"'\1"}/g'
done

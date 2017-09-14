#!/bin/bash
#=================================================
# name:   pa-lock-mic.sh
# author: Pawel Bogut <http://pbogut.me>
# date:   14/09/2017
#=================================================
lvl=${1:-16650}
echo "Locking volume on $lvl level."
echo "Press Ctrl-C to exit."
while :; do
  pacmd set-source-volume alsa_input.pci-0000_00_1b.0.analog-stereo $lvl
  sleep 0.1s
done

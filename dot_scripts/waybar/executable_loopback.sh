#!/usr/bin/env bash
#=================================================
# name:   loopback
# author: Pawel Bogut <pbogut@pbogut.me>
# date:   10/01/2026
#=================================================
toggle=false
if [[ $1 == 'toggle' ]]; then
  toggle=true
fi

if $toggle; then
  if ! pgrep -x pw-loopback > /dev/null 2>&1; then
    echo ""
    pw-loopback \
      -n fifine-sidetone \
      -l 10 \
      -C alsa_input.usb-Fifine_Microphones_fifine_Microphone_REV1.0-00.analog-stereo &
  else
    pkill -x pw-loopback
    echo ""
  fi
else
  if ! pgrep -x pw-loopback > /dev/null 2>&1; then
    echo ""
  else
    echo ""
  fi
fi

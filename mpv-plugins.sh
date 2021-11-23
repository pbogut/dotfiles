#!/usr/bin/env bash
#=================================================
# name:   mpv-plugins
# author: Pawel Bogut <https://pbogut.me>
# date:   22/11/2021
#=================================================
dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

mpv_mpris() {
  mpris=~/Projects/github.com/hoyon/mpv-mpris
  if [[ -d $mpris ]]; then
    git pullff
  else
    git cl hoyon/mpv-mpris
  fi
  cd $mpris && make && make install
}

mpvDLNA() {
  mkdir -p ~/.config/mpv/scripts
  dlna=~/Projects/github.com/chachmu/mpvDLNA
  if [[ -d $dlna ]]; then
    cd $dlna && git pullff
  else
    git clone git@github.com:chachmu/mpvDLNA.git "$dlna"
  fi
  ln -sf "$dlna" ~/.config/mpv/scripts/mpvDLNA
}

mpv_mpris
mpvDLNA

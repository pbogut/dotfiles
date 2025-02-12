#!/usr/bin/env bash
#=================================================
# name:   install
# author: Pawel Bogut <pbogut@pbogut.me>
# date:   12/02/2025
#=================================================
dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

dirs=(/opt/zen-browser-bin)

for d in "${dirs[@]}"; do
  if [[ -d "$d" ]]; then
    mkdir -p "$d/defaults/pref"
    cp "$dir/program/config.js" "$d/config.js"
    cp "$dir/program/defaults/pref/config-prefs.js" "$d/defaults/pref/config-prefs.js"
  fi
done

#!/usr/bin/env bash
#=================================================
# name:   executable_media_sync
# author: Pawel Bogut <pbogut@pbogut.me>
# date:   28/10/2025
#=================================================
if mount | grep '/run/media/' >/dev/null 2>&1; then
  grep -e Dirty: -e Writeback: /proc/meminfo | sed -E 'N;s,.* ([0-9]+) (kB)\n.* ([0-9]+) (kB),\1 \3,g' | awk '{printf "%.0f MB / %.2f MB", ($1/1024), ($2/1024)}'
  exit 0
fi
exit 1

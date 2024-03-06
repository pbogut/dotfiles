#!/bin/bash
#=================================================
# name:   i3-storage-stats.sh
# author: Pawel Bogut <http://pbogut.me>
# date:   14/12/2017
#=================================================

if [[ $(mount | grep '/run/media/') ]]; then
  grep -e Dirty: -e Writeback: /proc/meminfo |sed -E 'N;s,.* ([0-9]+) (kB)\n.* ([0-9]+) (kB),\1/\3,g'
else
  echo -n
fi

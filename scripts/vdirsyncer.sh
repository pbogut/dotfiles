#!/bin/bash
#=================================================
# name:   vdirsyncer.sh
# author: Pawel Bogut <https://pbogut.me>
# date:   25/01/2019
#=================================================

echo "start $(date) $(date '+%s')" >> /tmp/_vdircron
/usr/bin/vdirsyncer sync >> /tmp/_vdircron 2>&1
echo "end $(date) $(date '+%s')" >> /tmp/_vdircron

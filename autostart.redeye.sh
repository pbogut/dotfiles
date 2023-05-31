#!/bin/bash
#=================================================
# name:   .redeye.autostart.sh
# author: Pawel Bogut <https://pbogut.me>
# date:   09/08/2018
#=================================================
rerun barriers "barriers --disable-crypto"
rerun picom "picom -b --xrender-sync-fence"
rerun gamemode "gamemode.sh --watch"

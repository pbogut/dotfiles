#!/bin/bash
#=================================================
# name:   .redeye.autostart.sh
# author: Pawel Bogut <https://pbogut.me>
# date:   09/08/2018
#=================================================
#rerun barriers "barriers --disable-crypto"
rerun gamemode "$HOME/.scripts/sway/gamemode.sh --watch"
rerun kwalletd "kwalletd5"


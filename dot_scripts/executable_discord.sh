#!/usr/bin/env bash
#=================================================
# name:   discord
# author: Pawel Bogut <https://pbogut.me>
# date:   19/03/2022
#=================================================
flatpak kill io.github.trigg.discover_overlay
killall discord
flatpak run io.github.trigg.discover_overlay &
discord --enable-features=UseOzonePlatform --ozone-platform=wayland

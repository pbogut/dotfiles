#!/usr/bin/env bash
#=================================================
# name:   discord
# author: Pawel Bogut <https://pbogut.me>
# date:   19/03/2022
#=================================================
# discord --enable-features=UseOzonePlatform --ozone-platform=wayland ||
flatpak run --socket=wayland com.discordapp.Discord --enable-features=UseOzonePlatform --ozone-platform=wayland

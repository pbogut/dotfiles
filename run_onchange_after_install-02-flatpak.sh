#!/usr/bin/env bash
#=================================================
# name:   run_once_after_install-flatpak
# author: pbogut <pbogut@pbogut.me>
# date:   06/03/2024
#=================================================
flatpak remote-add \
    --if-not-exists --user \
    flathub https://dl.flathub.org/repo/flathub.flatpakrepo

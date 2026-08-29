#!/usr/bin/env bash
#=================================================
# name:   run_once_after_install-pip
# author: pbogut <pbogut@pbogut.me>
# date:   06/03/2024
#=================================================
pip install --user \
    neovim-remote \
    steamctl \
    trakt.py \
    visidata \
    --upgrade \
    --break-system-packages

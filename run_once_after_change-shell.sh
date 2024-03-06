#!/usr/bin/env bash
#=================================================
# name:   run_once_after_change-shell
# author: pbogut <pbogut@pbogut.me>
# date:   06/03/2024
#=================================================
if [[ -n "$(command -v zsh)" ]]; then
    if [[ "$SHELL" == "$(which zsh)" ]]; then
        exit 0
    fi
    chsh "$(id -un)" -s "$(which zsh)"
fi

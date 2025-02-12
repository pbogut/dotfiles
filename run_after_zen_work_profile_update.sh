#!/usr/bin/env bash
#=================================================
# name:   run_zen_work_profile_update
# author: Pawel Bogut <pbogut@pbogut.me>
# date:   12/02/2025
#=================================================
mkdir -p "$HOME/.zen/Work/chrome"
ln -sf "$HOME/.zen/Personal/zen-keyboard-shortcuts.json" "$HOME/.zen/Work/zen-keyboard-shortcuts.json"
rm -fr "$HOME/.zen/Work/chrome"
ln -sf "$HOME/.zen/Personal/chrome" "$HOME/.zen/Work/chrome"


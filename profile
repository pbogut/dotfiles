#!/bin/bash
#=================================================
# name:   .profile
# author: Pawel Bogut <http://pbogut.me>
# date:   11/11/2017
#=================================================
export PROFILE_LOADED=true

export PATH="$HOME/.scripts:$PATH"
export PATH="$HOME/.bin:$PATH"

export PATH="$PATH:$HOME/.local/bin"

export EDITOR="nvim"

export FZF_DEFAULT_OPTS="
  --filepath-word --reverse
  --bind=ctrl-e:preview-down,ctrl-y:preview-up,ctrl-s:toggle-preview
  --bind=ctrl-w:backward-kill-word
  --height 40%
  --cycle
  "

# that should work with bash / zsh and fish
source ~/.profile.local > /dev/null 2>&1


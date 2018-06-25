#!/bin/bash
#=================================================
# name:   .profile
# author: Pawel Bogut <pbogut@pbogut.net>
# date:   11/11/2017
#=================================================
export PROFILE_LOADED=true

export GOPATH="$HOME/.gocode"

export PATH="$HOME/.scripts:$PATH"
export PATH="$HOME/.bin:$PATH"

export PATH="$HOME/.local/bin:$PATH"
export PATH="$HOME/.npm/bin:$PATH"
export PATH="$HOME/.gocode/bin:$PATH"

export EDITOR="nvim"

export FZF_DEFAULT_OPTS="
  --filepath-word --reverse
  --bind=ctrl-e:preview-down,ctrl-y:preview-up,ctrl-s:toggle-preview
  --bind=ctrl-w:backward-kill-word
  --height 40%
  --cycle
  "

# set up unique TMPDIR per user
export TMPDIR="/tmp/$USER"
mkdir $TMPDIR -p

# that should work with bash / zsh and fish
touch ~/.profile.local
source ~/.profile.local >/dev/null 2>&1

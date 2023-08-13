#!/bin/bash
#=================================================
# name:   .profile
# author: Pawel Bogut <pbogut@pbogut.net>
# date:   11/11/2017
#=================================================
export PROFILE_LOADED=true

export GOPATH="$HOME/.gocode"

export PROJECTS="$HOME/Projects"
export DOTFILES="$PROJECTS/github.com/pbogut/dotfiles"
export SCRIPTS="$HOME/.scripts"
export PATH="$SCRIPTS:$PATH"

export PATH="$HOME/.local/bin:$PATH"
export PATH="$HOME/.npm/bin:$PATH"
export PATH="$HOME/.yarn/bin:$PATH"
export PATH="$HOME/.gocode/bin:$PATH"
export PATH="$HOME/.cargo/bin:$PATH"
export PATH="$HOME/.gem/ruby/3.0.0/bin:$PATH"
export PATH="$HOME/.bin:$PATH"
export PATH="$HOME/.local/share/nvim/mason/bin:$PATH"

# export TERM=xterm-256color
export TERMINAL="alacritty"
export EDITOR="nvim"
export PAGER="less"
export LESS="-RXe"

export QT_QPA_PLATFORMTHEME=qt5ct

# place for my common python scripts
export PYTHONPATH="$SCRIPTS/_python"

export TMPDIR="/tmp/$USER"

if [[ -f "$HOME/.cargo/bin/sccache" ]]; then
  export RUSTC_WRAPPER="$HOME/.cargo/bin/sccache"
fi

source "$HOME/.profile.local"
# shellcheck disable=1090
source "$HOME/.profile.$(hostname)"

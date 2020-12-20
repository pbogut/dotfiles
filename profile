#!/bin/bash
#=================================================
# name:   .profile
# author: Pawel Bogut <pbogut@pbogut.net>
# date:   11/11/2017
#=================================================
export GOPATH="$HOME/.gocode"

export PATH="$HOME/.scripts:$PATH"
export PATH="$HOME/.bin:$PATH"

export PATH="$HOME/.local/bin:$PATH"
export PATH="$HOME/.npm/bin:$PATH"
export PATH="$HOME/.gocode/bin:$PATH"

export TERM=xterm-256color
export TERMINAL="urxvt"
export EDITOR="nvim"
export PAGER="less"
export LESS="-RXe"

export QT_QPA_PLATFORMTHEME=qt5ct
export QT_STYLE_OVERRIDE=gtk2

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

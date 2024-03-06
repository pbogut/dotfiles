#!/bin/bash
(if [[ "$1" == "--tmux" || "$1" == "-t" ]]; then
    urxvt -e zsh -ic "~/.scripts/tmuxin.sh "'"'"`pwd`"'"'""
else
    urxvt -cd "`pwd`"
fi) > /dev/null 2>&1 &

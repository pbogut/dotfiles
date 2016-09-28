#!/bin/bash
if [ "$1" == "--tmux" ]; then
    urxvt -cd "`xcwd`" -e "zsh -ic tmux"
else
    urxvt -cd "`xcwd`"
fi
#-e zsh -ic tmux

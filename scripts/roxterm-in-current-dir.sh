#!/bin/bash
if [ "$1" == "--tmux" ]; then
    roxterm --separate -d "`xcwd`" -e "zsh -ic tmux"
else
    roxterm --separate -d "`xcwd`"
fi
#-e zsh -ic tmux

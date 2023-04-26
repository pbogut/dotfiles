#!/usr/bin/env zsh
#=================================================
# name:   title
# author: author <author_contact>
# date:   26/04/2023
#=================================================
precmd () {print -Pn "\e]0;$TERM\a"}

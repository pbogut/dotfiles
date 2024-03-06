#!/usr/bin/env zsh
#=================================================
# name:   title
# author: pbogut <pbogut@pbogut.me>
# date:   26/04/2023
#=================================================
precmd () {print -Pn "\e]0;zsh\a"}
preexec () {
  print -Pn "\e]0;${1%% *}\a"
}

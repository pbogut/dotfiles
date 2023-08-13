#!/usr/bin/env zsh
#=================================================
# name:   pwd-history
# author: Pawel Bogut <https://pbogut.me>
# date:   12/11/2021
#=================================================

separator=":::::::::"

function zshaddhistory() {
	echo "${PWD}${separator}${1%%$'\n'}" >> ~/.zsh_history_ext
}

function jog() {
  cmd=$(grep -v "jog" ~/.zsh_history_ext |
    grep -a --color=never "${PWD}${separator}" |
    sed "s,.*${separator},," |
    fzf +s)
      if [[ $? -eq 0 ]]; then
        eval $cmd
      fi
}

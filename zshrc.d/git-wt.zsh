#!/usr/bin/env zsh
#=================================================
# name:   git-wt
# author: author <author_contact>
# date:   29/03/2023
#=================================================

# Zsh completion
_gitwt_get_command_list() {
  echo "add" \
    "list" \
    "lock" \
    "move" \
    "remove" \
    "checkout" \
    "repair" \
    "unlock"
}

_gitwt () {
  local state
  _arguments '1: :->arg1' '2: :->arg2' '3: :->arg3'
      if [[ ${words[2]} =~ "wt" ]]; then
        if [[ -z ${words[3]} ]]; then
          compadd $(_gitwt_get_command_list)
          return 0
        fi
        if [[ ${words[3]} =~ "lock" ]] && [[ ! $words =~ "--reason" ]]; then
          compadd -- "--reason"
        fi
        if [[ ${words[3]} =~ "remove|move|repair|lock|unlock" ]]; then
          compadd $(git-wt list --orphans | awk '{print $1}')
          return 0
        fi
        if [[ ${words[3]} =~ "checkout" ]]; then
          compadd $(git branch -r | sed -E 's,.[^/]+/,,')
          return 0
        fi
        if [[ ${words[3]} =~ "add" ]]; then
          compadd $(git-wt list --orphans | awk '{print $1}')
          return 0
        fi
      fi

    _git
}

compdef _gitwt "git-wt"
compdef _gitwt "git"

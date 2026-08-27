#!/usr/bin/env zsh
#=================================================
# name:   mise
# author: Pawel Bogut <pbogut@pbogut.me>
# date:   27/08/2026
#=================================================
eval "$(mise activate zsh 2>/dev/null)"
# Ensure local scripts are always a priority before mise
_mise_custom_path() {
  local IFS=':'
  local -a new_path
  for p in $PATH; do
    [[ $p != "$HOME/.scripts" ]] && new_path+=("$p")
  done
  path=("$HOME/.scripts" $new_path)
}
add-zsh-hook precmd _mise_custom_path

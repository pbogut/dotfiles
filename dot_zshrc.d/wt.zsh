#!/usr/bin/env zsh
#=================================================
# name:   wt
# author: Pawel Bogut <pbogut@assuredpharmacy.co.uk>
# date:   26/07/2022
#=================================================
wt() {
  __wt_base_dir() {
    base_dir="$(git worktree list | grep '(bare)$' | awk '{print $1}')"
    if [[ $base_dir =~ \.bare$ ]]; then
      base_dir="$(dirname "$base_dir")"
    fi
    echo "$base_dir"
  }

  if ! git rev-parse --git-dir > /dev/null 2>&1; then
    echo "This command only works in git ropository." &&
    return 1
  fi

  __wt_select_dir() {
    git wt list | column --table | fzf | awk '{print $1}'
  }

  cd $(__wt_base_dir) || return 2
  newdir="$(__wt_select_dir)"
  if [[ "$newdir" != "" ]]; then
    touch "$newdir"
    cd "$newdir"
  else
    cd - > /dev/null
  fi
}

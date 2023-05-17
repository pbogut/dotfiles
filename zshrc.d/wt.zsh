#!/usr/bin/env zsh
#=================================================
# name:   wt
# author: Pawel Bogut <pbogut@assuredpharmacy.co.uk>
# date:   26/07/2022
#=================================================
wt() {
  __wt_list() {
    git worktree list | grep -v '(bare)$' | while read -r tpath commit branch; do
      rpath=$(realpath "$tpath" --relative-to="$cwd" )
      echo "$branch $rpath $commit"
    done
  }

  __wt_usage() {
    echo "Ussage: wt [ACTION] [OPTIONS]"
    echo ""
    echo "Actions:"
    echo "  create|c <worktree-name>     create new worktree with new branch"
    echo "  delete|d <worktree-name>     delete worktree with new branch"
    echo ""
    echo "Options:"
    echo "  -h, --help     display this help and exit"
  }

  __wt_base_dir() {
    git worktree list | grep '(bare)$' | awk '{print $1}'
  }

  __wt_select_dir() {
    __wt_list | column --table | fzf | awk '{print $2}'
  }

  git rev-parse --absolute-git-dir > /dev/null 2>&1
  if [[ $? -gt 0 ]]; then
    echo "This command only works in git ropository." &&
    return 1
  fi

  action="list"
  worktree=""

  while test $# -gt 0; do
    case "$1" in
      create|c)
        action="create"
        shift
        if [[ -z "$1" ]]; then
          __wt_usage
          return 1
        fi
        worktree=$1
        shift
        ;;
      delete|d)
        action="delete"
        shift
        if [[ -n $1 ]]; then
          worktree=$1
          shift
        fi
        ;;
      --help|-h)
        __wt_usage
        return 0
        ;;
      *)
        __wt_usage
        return 1
        ;;
    esac
  done

  cwd=$(realpath $PWD)

  if [[ "$action" == "list" ]]; then
    newdir="$(__wt_select_dir)"
  fi

  if [[ "$action" == "create" ]]; then
    cd $(__wt_base_dir) || return 2
    git fetch --all
    newdir=$(__wt_base_dir)/$worktree
    git worktree add "$(__wt_base_dir)/$worktree" "$worktree" 2>/dev/null || (
      git branch "$worktree" "origin/$(git branch | grep '^\*' | sed 's/\* //')" &&
      git worktree add "$(__wt_base_dir)/$worktree" "$worktree" &&
      cd "$worktree" &&
      git branch --unset-upstream
    )
    cd -
  fi

  if [[ "$action" == "delete" ]]; then
    wtdir="$(__wt_base_dir)/$worktree"
    if [[ -z "$worktree" ]]; then
      wtdir="$(__wt_select_dir)"
    fi
    base_dir=$(__wt_base_dir)
    real_wtdir="$(realpath "$wtdir")"
    git worktree remove "$real_wtdir"
    if [[ $? -eq 128 ]]; then
      echo "Do you want to remove this folder? [y/N]"
      read -r answer
      if [[ "$answer" == "y" ]]; then
        rm -fr "$real_wtdir"
        if [[ $? -gt 0 ]]; then # no permissions
          echo "Do you want to remove worktree as root? [y/N]"
          read -r answer
          if [[ "$answer" == "y" ]]; then
            sudo rm -rf "$real_wtdir"
          fi
        fi
      fi
    elif [[ $? -gt 0 ]]; then # failed to remove
      cd "$real_wtdir" && git diff && cd -
      # ask if we should remove
      echo "Do you want to force remove worktree? [y/N]"
      read -r answer
      if [[ "$answer" == "y" ]]; then
        git worktree remove --force "$real_wtdir"
        if [[ $? -gt 0 ]]; then # no permissions
          echo "Do you want to remove worktree as root? [y/N]"
          read -r answer
          if [[ "$answer" == "y" ]]; then
            sudo rm -rf "$real_wtdir"
          fi
        fi
      fi
    fi
    if [[ "$real_wtdir" == "$cwd" ]]; then
      newdir=$base_dir
    fi
  fi

  if [[ "$newdir" != "" ]]; then
    cd "$newdir"
  fi
}

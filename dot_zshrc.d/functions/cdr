#!/bin/zsh
#=================================================
# name:   cd-root.zsh
# author: Pawel Bogut <pbogut@ukpos.com> <http://pbogut.me>
# date:   07/06/2017
#=================================================

cdr() {
  dir=${1:-$(pwd)}
  root_expr="^.git$\|^composer.json$"
  is_root=$(ls -a $dir | grep "$root_expr")
  cont=$2

  if [[ ! $is_root == "" ]] && [[ ! $cont == "y" ]]; then
    echo "This is project root, wish to continue anyway (y)?"
    read -sk cont
  else
    cont=y
  fi

  if [[ $cont == "y" ]];then
    dir=$(dirname $dir)
    is_root=$(ls -a $dir | grep "$root_expr")

    if [[ ! $dir == "/" ]]; then
      if [[ $is_root == "" ]]; then
        cdr $dir y
      fi
    else
      echo "Could not find project root"
    fi

    if [[ ! $is_root == "" ]]; then
      cd "$dir"
    fi
  fi
}

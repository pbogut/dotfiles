#!/bin/bash
#=================================================
# name:   haskell-deps.sh
# author: Pawel Bogut <https://pbogut.me>
# date:   20/02/2021
#=================================================
cmd=$1
package="go"
while [[ $package != "" ]]; do
  missing=$($cmd 2>&1| grep 'libHS' | sed -E 's,.*: libHS(.*)-[0-9]+[0-9\-\.]+.*$,\1,')
  package="haskell-${missing,,}"
  echo "$package"
  if [[ $package != "" ]]; then
    paru -S "$package"
  fi
done

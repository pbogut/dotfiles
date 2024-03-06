#!/bin/bash
#=================================================
# name:   fzf-preview.sh
# author: Pawel Bogut <https://pbogut.me>
# date:   30/01/2021
#=================================================

file="$1"
line=0

print_file() {
    type bat > /dev/null 2>&1
    if [[ $? == 0 ]]; then
        bat -p --color=always "$file"
    else
        cat "$file"
    fi
}

print_diff() {
    git diff "$file" > /dev/null 2>&1
    if [[ $? == 0 ]]; then
        git diff --color=always -- "$file" | sed 1,4d
    fi
}

print_context() {
  start=$(($line - 12))
  [[ $start -lt 1 ]] && start=0
  bat -H $line -p --color=always $file | tail -n+$start | head -n30
  echo '-----------------------------------------------------------------------'
}

find_file() {
  rest=$file
  while read tfile rest <<< $rest; do
    if [[ -f $tfile ]] || [[ $tfile"" == "" ]]; then
      break
    fi
  done
  file=$tfile
}

if [[ $file =~ :[0-9]+:[0-9]+:  ]]; then
  line=$(echo $file | sed -E 's,.*:([0-9]+):[0-9]+:.*,\1,')
  file=$(echo $file | sed -E 's,(.*):[0-9]+:[0-9]+:.*,\1,')
  print_context;
fi

find_file

if [[ -f $file ]]; then
    (print_diff; print_file) | head -n 500
else
    echo "Preview is not available."
fi

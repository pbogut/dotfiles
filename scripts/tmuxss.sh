#!/bin/bash
if [[ -z "$1" ]]; then
    name=`basename $0`
    echo "$name - Tmux Single Session"
    echo ""
    echo "Usage: $name  <session_name>"
    exit
fi
if [[ -z "$TMUX"  ]]; then
  sessions=`tmux list-sessions -F '---#{session_name}---'`
  if [[ $sessions == *"---$1---"*  ]]; then
    exec tmux new-session -t $1
  else
    exec tmux new-session -s $1
  fi
fi

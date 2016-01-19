#!/bin/bash
if [[ -z "$TMUX"  ]]; then
  sessions=`tmux list-sessions -F '---#{session_name}---'`
  if [[ $sessions == *"---$1---"*  ]]; then
    exec tmux new-session -t $1 \; new-window
  else
    exec tmux new-session -s $1
  fi
fi

#!/bin/bash
if [[ -z "$TMUX"  ]]; then
  sessions=`tmux list-sessions -F '---#{session_name}---'`
  if [[ $sessions == *"---Main---"*  ]]; then
    exec tmux new-session -t Main \; new-window
  else
    exec tmux new-session -s Main
  fi
fi

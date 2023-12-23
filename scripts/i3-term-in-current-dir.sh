#!/bin/bash
cwd=$HOME

tmux=false
zellij=false
project=false
force_new=false


usage() {
  echo "Ussage: ${0##*/} [OPTIONS]"
  echo ""
  echo "Options:"
  echo "  -h, --help     display this help and exit"
}

while test $# -gt 0; do

  case "$1" in
    --new-workspace)
      i3-create-empty-workspace.py
      shift
      ;;
    --tmux)
      tmux=true
      shift
      ;;
    --zellij)
      zellij=true
      shift
      ;;
    --project)
      project=true
      shift
      ;;
    --force-new)
      force_new=true
      shift
      ;;
    --help|-h)
      usage
      exit 0
      ;;
    *)
      usage
      exit 1
      ;;
  esac
done

cd "$cwd" || cd "$HOME" || exit

__start_terminal() {
  start=$(date '+%s')

  if ! "$@"; then
    end=$(date '+%s')
    if [[ $((end-start)) -lt 5 ]]; then
      notify-send "Terminal $1 failed to start, falling back to xterm"
      xterm
    fi
  fi
}

if $project; then
  cd "$cwd" >/dev/null || exit 1
  __start_terminal "$TERMINAL" -e env TERM=xterm-256color tmux-project
  cd - >/dev/null || exit 1
  exit 0
fi

if $tmux; then
  title=$(xtitle)
  session="${title##*\|t}"

  if [[ $title =~ \|t\$[0-9]+$ ]] && ! $force_new; then
    tmux new-window -t "$session" -c "#{pane_current_path}"
    exit 0
  else
    __start_terminal "$TERMINAL" -e env TERM=xterm-256color tmux new-session -c "$cwd"
    exit 0
  fi
fi

if $zellij; then
  __start_terminal "$TERMINAL" -e zl options --default-cwd "$cwd"
  exit 0
fi

if which "$TERMINAL"; then
  __start_terminal "$TERMINAL"
elif which alacritty; then
  __start_terminal alacritty
elif which foot; then
  __start_terminal foot
elif which urxvt; then
  __start_terminal urxvt
else
  xterm
fi

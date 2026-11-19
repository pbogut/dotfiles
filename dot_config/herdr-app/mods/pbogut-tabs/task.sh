#!/usr/bin/env bash
set -uo pipefail

name=$1 progress=$2 close=$3
shift 3
unset HERDR_ENV HERDR_PANE_ID HERDR_SOCKET_PATH HERDR_TAB_ID HERDR_WORKSPACE_ID

hc label "$HC_TERMINAL_ID" "pbogut.task=$name" "pbogut.task.progress=$progress" \
	"pbogut.task.state=running" >/dev/null || exit
# Let Ctrl+C reach the foreground command and keep its exit status for inspection.
trap ':' INT
if root=$(git rev-parse --show-toplevel 2>/dev/null); then cd -- "$root" || exit; fi
env -- "$@"
status=$?
if [[ $close == true ]]; then exit "$status"; fi

state=success
((status == 0)) || state=failed
hc label "$HC_TERMINAL_ID" "pbogut.task.state=$state" >/dev/null || exit
printf '\n%s exited with status %d.\n' "$name" "$status"
read -r -p 'Press Enter to close this tab. ' _ || true
exit "$status"

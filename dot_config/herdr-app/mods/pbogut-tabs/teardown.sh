#!/usr/bin/env bash
set -uo pipefail

[[ $# == 3 ]] || exit 2
export HERDR_PROJECT_DIR=$1
script=$2
token=$3
[[ $script == /* ]] || script="$HERDR_PROJECT_DIR/$script"
unset HERDR_ENV HERDR_PANE_ID HERDR_SOCKET_PATH HERDR_TAB_ID HERDR_WORKSPACE_ID

finish() {
	local status=$?
	if ((status != 0)); then
		printf '\nTeardown failed (exit %d): %s\n' "$status" "$script"
		printf 'The project stays open. Use Close project again to retry.\n'
		# Cleanup scripts can remove the directory the terminal started in.
		cd / || return
		hc label "$HC_TERMINAL_ID" "pbogut.teardown.state=failed" >/dev/null || true
		read -r -p 'Press Enter to close this tab. ' _ || true
	fi
}

hc label "$HC_TERMINAL_ID" "pbogut.teardown=$token" "pbogut.teardown.state=running" >/dev/null || exit
trap finish EXIT
if worktree=$(git rev-parse --show-toplevel 2>/dev/null); then
	cd -- "$worktree" || exit
fi
export HERDR_WORKTREE_DIR
HERDR_WORKTREE_DIR=$(pwd -P) || exit
printf 'Tearing down %s\n%s\n\n' "$HERDR_WORKTREE_DIR" "$script"
bash -- "$script"
status=$?
((status == 0)) || exit "$status"
cd / || exit
hc label "$HC_TERMINAL_ID" "pbogut.teardown.state=success" >/dev/null || exit

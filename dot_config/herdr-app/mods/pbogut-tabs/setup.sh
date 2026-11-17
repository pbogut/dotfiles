#!/usr/bin/env bash
set -uo pipefail

[[ $# == 5 && $1 =~ ^(check|run)$ ]] || exit 2
mode=$1
app_home=$2
export HERDR_PROJECT_DIR=$3
script=$4
token=$5
[[ $script == /* ]] || script="$HERDR_PROJECT_DIR/$script"
unset HERDR_ENV HERDR_PANE_ID HERDR_SOCKET_PATH HERDR_TAB_ID HERDR_WORKSPACE_ID

finish() {
	local status=$?
	[[ ! ${lock_fd:-} ]] || exec {lock_fd}>&-
	if ((status != 0)); then
		printf '\nSetup failed (exit %d): %s\n' "$status" "$script"
		printf 'Reopen the project or use Reload project config to retry.\n'
		hc label "$HC_TERMINAL_ID" "pbogut.setup.state=failed" >/dev/null || true
		read -r -p 'Press Enter to close this tab. ' _ || true
	fi
}

if [[ $mode == run ]]; then
	hc label "$HC_TERMINAL_ID" "pbogut.setup=$token" "pbogut.setup.state=running" >/dev/null || exit
	trap finish EXIT
fi

export HERDR_WORKTREE_DIR
if worktree=$(git rev-parse --show-toplevel 2>/dev/null); then
	cd -- "$worktree" || exit
fi
HERDR_WORKTREE_DIR=$(pwd -P) || exit
# A recreated worktree at the same path needs setup again.
identity_path=$HERDR_WORKTREE_DIR
[[ ! -e $HERDR_WORKTREE_DIR/.git ]] || identity_path=$HERDR_WORKTREE_DIR/.git
identity=$(stat -c '%d:%i:%W' -- "$identity_path") || exit
key=$(printf '%s\0%s\0' "$HERDR_WORKTREE_DIR" "$identity" | sha256sum) || exit
key=${key%% *}
state="$app_home/state/project-setup"
if [[ $mode == run ]]; then
	(
		umask 077
		mkdir -p -- "$state"
	) || exit
	exec {lock_fd}>"$state/$key.lock" || exit
	flock "$lock_fd" || exit
fi

# Hash after taking the lock, since the script may change while waiting.
hash=$(sha256sum <"$script") || exit
hash=${hash%% *}
marker="$state/$key.$hash"

if [[ $mode == check ]]; then
	printf '%s\n' "$hash"
	[[ ! -f $marker ]] || exit 0
	exit 75
fi

hc label "$HC_TERMINAL_ID" "pbogut.setup.hash=$hash" >/dev/null || exit
if [[ ! -f $marker ]]; then
	printf 'Setting up %s (SHA-256 %s)\n%s\n\n' "$HERDR_WORKTREE_DIR" "$hash" "$script"
	bash -- "$script"
	status=$?
	((status == 0)) || exit "$status"
	umask 077
	tmp=$(mktemp "$state/.setup.XXXXXX") || exit
	if ! printf 'project=%s\nworktree=%s\nsha256=%s\n' \
		"$HERDR_PROJECT_DIR" "$HERDR_WORKTREE_DIR" "$hash" >"$tmp" ||
		! mv -f -- "$tmp" "$marker"; then
		rm -f -- "$tmp"
		exit 1
	fi
fi
exec {lock_fd}>&-
unset lock_fd
hc label "$HC_TERMINAL_ID" "pbogut.setup.state=success" >/dev/null || exit

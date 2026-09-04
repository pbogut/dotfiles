#!/usr/bin/env bash

herdr_resolve_socket() {
	local socket_path=${HERDR_SOCKET_PATH:-}
	local herdr_bin=${HERDR_BIN_PATH:-herdr}

	if [[ -z $socket_path ]]; then
		socket_path=$("$herdr_bin" status server 2>/dev/null | sed -n 's/^socket: //p')
	fi
	[[ -n $socket_path ]] || {
		echo "Could not determine the Herdr socket" >&2
		return 1
	}
	if [[ $socket_path == /* ]]; then
		socket_path=$(realpath -m -- "$socket_path") || return 1
	fi
	printf '%s\n' "$socket_path"
}

herdr_api_request() {
	local method=$1 params=$2 socket_path request response

	socket_path=$(herdr_resolve_socket) || return 1
	request=$(jq -cn \
		--arg id "pbogut.project-layout:$BASHPID:$RANDOM" \
		--arg method "$method" \
		--argjson params "$params" \
		'{id: $id, method: $method, params: $params}') || return 1
	response=$(python3 -c '
import socket
import sys

with socket.socket(socket.AF_UNIX) as client:
    client.settimeout(5)
    client.connect(sys.argv[1])
    client.sendall((sys.argv[2] + "\n").encode())
    with client.makefile() as response:
        line = response.readline()
if not line:
    raise SystemExit(1)
print(line, end="")
' "$socket_path" "$request") || return 1
	if ! jq -e 'type == "object"' >/dev/null 2>&1 <<<"$response"; then
		echo "Invalid response from Herdr API" >&2
		return 1
	fi
	if jq -e '.error != null' >/dev/null 2>&1 <<<"$response"; then
		jq -r '.error.message // .error // "Herdr API error"' <<<"$response" >&2
		return 1
	fi
	printf '%s\n' "$response"
}

herdr_plugin_config_dir() {
	local plugin_id=${HERDR_PLUGIN_ID:-pbogut.project-layout}
	local herdr_bin=${HERDR_BIN_PATH:-herdr}

	if [[ -n ${HERDR_PLUGIN_CONFIG_DIR:-} ]]; then
		printf '%s\n' "$HERDR_PLUGIN_CONFIG_DIR"
		return
	fi
	"$herdr_bin" plugin config-dir "$plugin_id" 2>/dev/null
}

herdr_workspace_root_id() {
	local cwd=$1 root_id

	read -r root_id _ < <(printf '%s\0' "$cwd" | sha256sum)
	printf '%s\n' "$root_id"
}

herdr_workspace_root_file() {
	local workspace_id=$1 config_dir socket_path session_key

	[[ $workspace_id =~ ^[A-Za-z0-9_-]+$ ]] || return 1
	config_dir=$(herdr_plugin_config_dir) || return 1
	socket_path=$(herdr_resolve_socket) || return 1
	read -r session_key _ < <(printf '%s\0' "$socket_path" | sha256sum)
	printf '%s/workspace-roots/%s/%s.json\n' "$config_dir" "$session_key" "$workspace_id"
}

herdr_report_workspace_root() {
	local workspace_id=$1 cwd=$2 root_id
	local herdr_bin=${HERDR_BIN_PATH:-herdr}
	local source_id="plugin:${HERDR_PLUGIN_ID:-pbogut.project-layout}:workspace-root"

	root_id=$(herdr_workspace_root_id "$cwd") || return 1
	"$herdr_bin" workspace report-metadata "$workspace_id" \
		--source "$source_id" \
		--token "workspace_root_id=$root_id" >/dev/null
}

herdr_record_workspace_root() {
	local workspace_id=$1 cwd=$2 root_id root_file root_dir lock_fd tmp

	[[ -d $cwd ]] || return 1
	cwd=$(realpath -e -- "$cwd") || return 1
	root_id=$(herdr_workspace_root_id "$cwd") || return 1
	root_file=$(herdr_workspace_root_file "$workspace_id") || return 1
	root_dir=${root_file%/*}
	umask 077
	mkdir -p -- "$root_dir" || return 1
	[[ -d $root_dir && -O $root_dir && ! -L $root_dir ]] || return 1
	chmod 700 "$root_dir" || return 1
	if ! exec {lock_fd}>"$root_dir/.lock"; then
		return 1
	fi
	if ! flock "$lock_fd"; then
		exec {lock_fd}>&-
		return 1
	fi
	tmp=$(mktemp "$root_dir/.workspace-root.XXXXXX") || {
		exec {lock_fd}>&-
		return 1
	}
	if ! jq -cn --arg cwd "$cwd" --arg id "$root_id" \
		'{cwd: $cwd, id: $id}' >"$tmp" ||
		! chmod 600 "$tmp" ||
		! mv -f -- "$tmp" "$root_file"; then
		rm -f -- "$tmp"
		exec {lock_fd}>&-
		return 1
	fi
	exec {lock_fd}>&-
	herdr_report_workspace_root "$workspace_id" "$cwd" 2>/dev/null || true
}

herdr_get_workspace_root() {
	local workspace_id=$1 root_file record cwd expected_id actual_id

	root_file=$(herdr_workspace_root_file "$workspace_id") || return 1
	[[ -f $root_file && ! -L $root_file && -O $root_file ]] || return 1
	record=$(<"$root_file") || return 1
	cwd=$(jq -er '.cwd | select(type == "string" and length > 0)' <<<"$record" 2>/dev/null) || return 1
	expected_id=$(jq -er '.id | select(type == "string" and length == 64)' <<<"$record" 2>/dev/null) || return 1
	[[ -d $cwd ]] || return 1
	cwd=$(realpath -e -- "$cwd") || return 1
	actual_id=$(herdr_workspace_root_id "$cwd") || return 1
	[[ $actual_id == "$expected_id" ]] || return 1
	printf '%s\n' "$cwd"
}

herdr_forget_workspace_root() {
	local workspace_id=$1 root_file

	root_file=$(herdr_workspace_root_file "$workspace_id") || return 1
	rm -f -- "$root_file"
}

herdr_acquire_topology_lock() {
	local workspace_id=$1 socket_path lock_key lock_dir lock_path lock_fd inherited_fd

	[[ -n $workspace_id ]] || {
		echo "No Herdr workspace is available" >&2
		return 1
	}
	socket_path=$(herdr_resolve_socket) || return 1
	read -r lock_key _ < <(printf '%s\0%s\0' "$socket_path" "$workspace_id" | sha256sum)
	inherited_fd=${HERDR_TOPOLOGY_LOCK_FD:-}
	if [[ ${HERDR_TOPOLOGY_LOCK_KEY:-} == "$lock_key" && $inherited_fd =~ ^[0-9]+$ && -e /proc/$$/fd/$inherited_fd ]]; then
		HERDR_SOCKET_PATH=$socket_path
		export HERDR_SOCKET_PATH
		return 0
	fi

	lock_dir=${XDG_RUNTIME_DIR:-${XDG_CACHE_HOME:-$HOME/.cache}}/herdr/project-layout-locks
	umask 077
	mkdir -p -- "$lock_dir" || return 1
	[[ -O $lock_dir && ! -L $lock_dir ]] || {
		echo "Unsafe Herdr project lock directory: $lock_dir" >&2
		return 1
	}
	chmod 700 "$lock_dir" || return 1
	lock_path=$lock_dir/$lock_key.lock
	exec {lock_fd}>"$lock_path" || return 1
	flock "$lock_fd" || {
		exec {lock_fd}>&-
		return 1
	}

	HERDR_SOCKET_PATH=$socket_path
	HERDR_TOPOLOGY_LOCK_FD=$lock_fd
	HERDR_TOPOLOGY_LOCK_KEY=$lock_key
	HERDR_TOPOLOGY_LOCK_OWNER_PID=$BASHPID
	HERDR_TOPOLOGY_LOCK_PATH=$lock_path
	export HERDR_SOCKET_PATH HERDR_TOPOLOGY_LOCK_FD HERDR_TOPOLOGY_LOCK_KEY
	export HERDR_TOPOLOGY_LOCK_OWNER_PID HERDR_TOPOLOGY_LOCK_PATH
}

herdr_release_topology_lock() {
	local lock_fd=${HERDR_TOPOLOGY_LOCK_FD:-}

	[[ ${HERDR_TOPOLOGY_LOCK_OWNER_PID:-} == "$BASHPID" ]] || return 0
	if [[ $lock_fd =~ ^[0-9]+$ ]]; then
		flock -u "$lock_fd" || true
		exec {lock_fd}>&-
	fi
	unset HERDR_TOPOLOGY_LOCK_FD HERDR_TOPOLOGY_LOCK_KEY
	unset HERDR_TOPOLOGY_LOCK_OWNER_PID HERDR_TOPOLOGY_LOCK_PATH
}

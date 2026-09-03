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

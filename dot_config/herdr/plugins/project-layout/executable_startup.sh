#!/usr/bin/env bash

plugin_root=${HERDR_PLUGIN_ROOT:-$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)}
plugin_id=pbogut.project-layout
status=0

module_path() {
	local name=$1 source_name=executable_$1

	if [[ -f $plugin_root/$name ]]; then
		printf '%s\n' "$plugin_root/$name"
	elif [[ -f $plugin_root/$source_name ]]; then
		printf '%s\n' "$plugin_root/$source_name"
	else
		echo "Missing project-layout module: $name" >&2
		return 1
	fi
}

report_repo=$(module_path report-repo.sh) || exit 1
session_cache=$(module_path cache-opencode-session.sh) || exit 1
managed_tabs=$(module_path managed-tabs) || exit 1

HERDR_PLUGIN_ID=$plugin_id bash "$report_repo" --all || status=1
HERDR_PLUGIN_ID=$plugin_id bash "$session_cache" --all || status=1
HERDR_PLUGIN_ID=$plugin_id bash "$managed_tabs" --restore-all || status=1
exit "$status"

#!/usr/bin/env bash

herdr=${HERDR_BIN_PATH:-herdr}
source_id="plugin:${HERDR_PLUGIN_ID:-pbogut.repo-metadata}"

derive_repo() {
  local cwd=$1
  local common_dir project_dir branch

  common_dir=$(git -C "$cwd" rev-parse --path-format=absolute --git-common-dir 2>/dev/null) || return
  case ${common_dir##*/} in
    .git | .bare) project_dir=${common_dir%/*} ;;
    *) project_dir=$(git -C "$cwd" rev-parse --show-toplevel 2>/dev/null) || return ;;
  esac

  project=${project_dir##*/}
  branch=$(git -C "$cwd" branch --show-current 2>/dev/null)
  if [[ $branch =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}-(.+)$ ]]; then
    branch=${BASH_REMATCH[1]}
  fi
  feature=$branch
}

report_pane() {
  local pane_id=$1
  local -a feature_arg=(--clear-token feature)

  [[ -n $feature ]] && feature_arg=(--token "feature=$feature")
  "$herdr" pane report-metadata "$pane_id" \
    --source "$source_id" \
    --token "project=$project" \
    "${feature_arg[@]}" >/dev/null
}

report_workspace() {
  local workspace_id=$1
  local -a feature_arg=(--clear-token feature)

  [[ -n $feature ]] && feature_arg=(--token "feature=$feature")
  "$herdr" workspace report-metadata "$workspace_id" \
    --source "$source_id" \
    --token "project=$project" \
    "${feature_arg[@]}" >/dev/null
}

report_one() {
  local pane_id=$1
  local workspace_id=$2
  local cwd=$3

  [[ -n $pane_id && -n $workspace_id && -d $cwd ]] || return
  derive_repo "$cwd" || return
  report_pane "$pane_id"
  report_workspace "$workspace_id"
}

report_all() {
  local snapshot pane_id workspace_id cwd
  local -A reported_workspaces=()

  snapshot=$("$herdr" api snapshot) || return
  while IFS=$'\t' read -r pane_id workspace_id cwd; do
    [[ -n $pane_id ]] || continue
    derive_repo "$cwd" || continue
    report_pane "$pane_id"
    if [[ -z ${reported_workspaces[$workspace_id]:-} ]]; then
      report_workspace "$workspace_id"
      reported_workspaces[$workspace_id]=1
    fi
  done < <(jq -r '
    .result.snapshot.panes[] |
    [.pane_id, .workspace_id, (.foreground_cwd // .cwd)] |
    @tsv
  ' <<<"$snapshot")
}

if [[ ${1:-} == --all ]]; then
  report_all
  exit
fi

event=${HERDR_PLUGIN_EVENT_JSON:-}
[[ -n $event ]] || event='{}'
pane_id=${HERDR_PANE_ID:-$(jq -r '.data.pane_id // .data.pane.pane_id // empty' <<<"$event")}
[[ -n $pane_id ]] || exit

pane=$("$herdr" pane get "$pane_id") || exit
workspace_id=$(jq -r '.result.pane.workspace_id' <<<"$pane")
cwd=$(jq -r '.result.pane.foreground_cwd // .result.pane.cwd' <<<"$pane")
report_one "$pane_id" "$workspace_id" "$cwd"

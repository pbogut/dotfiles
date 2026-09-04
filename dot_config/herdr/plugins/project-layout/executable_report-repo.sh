#!/usr/bin/env bash

plugin_root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
# shellcheck source-path=SCRIPTDIR
# shellcheck source=lib/runtime.sh
source "$plugin_root/lib/runtime.sh"

herdr=${HERDR_BIN_PATH:-herdr}
source_id="plugin:${HERDR_PLUGIN_ID:-pbogut.project-layout}"

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
  derive_repo "$cwd" || return 0
  report_pane "$pane_id"
  report_workspace "$workspace_id"
}

report_all() {
  local snapshot pane_id workspace_id cwd root
  local -A reported_workspaces=()
  local -A recorded_roots=()

  snapshot=$("$herdr" api snapshot) || return
  while IFS=$'\t' read -r pane_id workspace_id cwd; do
    [[ -n $pane_id ]] || continue
    if [[ -z ${recorded_roots[$workspace_id]:-} ]]; then
      if root=$(herdr_get_workspace_root "$workspace_id"); then
        herdr_report_workspace_root "$workspace_id" "$root" >/dev/null 2>&1 || true
      else
        root=$(git -C "$cwd" rev-parse --show-toplevel 2>/dev/null) || root=$cwd
        herdr_record_workspace_root "$workspace_id" "$root" >/dev/null 2>&1 || true
      fi
      recorded_roots[$workspace_id]=1
    fi
    derive_repo "$cwd" || continue
    report_pane "$pane_id"
    if [[ -z ${reported_workspaces[$workspace_id]:-} ]]; then
      report_workspace "$workspace_id"
      reported_workspaces[$workspace_id]=1
    fi
  done < <(jq -r '
    .result.snapshot.panes |
    sort_by(.workspace_id, ((.pane_id | endswith(":p1")) | not))[] |
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
if [[ ${HERDR_PLUGIN_EVENT:-} == workspace.closed ]]; then
  workspace_id=$(jq -r '.data.workspace_id // empty' <<<"$event")
  [[ -z $workspace_id ]] || herdr_forget_workspace_root "$workspace_id" >/dev/null 2>&1 || true
  exit
fi

event_pane=$(jq -c '.data.pane // empty' <<<"$event")
if [[ ${HERDR_PLUGIN_EVENT:-} == pane.created && -n $event_pane ]]; then
  pane_id=$(jq -r '.pane_id // empty' <<<"$event_pane")
  workspace_id=$(jq -r '.workspace_id // empty' <<<"$event_pane")
  cwd=$(jq -r '.cwd // empty' <<<"$event_pane")
  if [[ $pane_id == "$workspace_id:p1" && -d $cwd ]]; then
    herdr_record_workspace_root "$workspace_id" "$cwd" >/dev/null 2>&1 || true
  fi
fi

pane_id=${HERDR_PANE_ID:-$(jq -r '.data.pane_id // .data.pane.pane_id // empty' <<<"$event")}
[[ -n $pane_id ]] || exit

if [[ -n $event_pane ]]; then
  workspace_id=$(jq -r '.workspace_id' <<<"$event_pane")
  cwd=$(jq -r '.foreground_cwd // .cwd' <<<"$event_pane")
else
  pane=$("$herdr" pane get "$pane_id") || exit
  workspace_id=$(jq -r '.result.pane.workspace_id' <<<"$pane")
  cwd=$(jq -r '.result.pane.foreground_cwd // .result.pane.cwd' <<<"$pane")
fi
report_one "$pane_id" "$workspace_id" "$cwd"

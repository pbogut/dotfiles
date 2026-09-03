#!/usr/bin/env bash

herdr=${HERDR_BIN_PATH:-herdr}
source_id="plugin:${HERDR_PLUGIN_ID:-pbogut.project-layout}"

valid_session_id() {
  local session_id=$1

  [[ -n $session_id && ${#session_id} -le 256 && $session_id != *$'\n'* && $session_id != *$'\r'* ]]
}

cache_pane() {
  local pane=$1
  local workspace_id session_id current

  [[ $(jq -r '.agent_session.agent // empty' <<<"$pane") == opencode ]] || return 0
  [[ $(jq -r '.agent_session.source // empty' <<<"$pane") == herdr:opencode ]] || return 0
  [[ $(jq -r '.agent_session.kind // empty' <<<"$pane") == id ]] || return 0

  workspace_id=$(jq -r '.workspace_id // empty' <<<"$pane")
  session_id=$(jq -r '.agent_session.value // empty' <<<"$pane")
  [[ -n $workspace_id ]] && valid_session_id "$session_id" || return 0

  current=$("$herdr" workspace get "$workspace_id" 2>/dev/null |
    jq -r '.result.workspace.tokens.opencode_session // empty') || return 1
  [[ $current == "$session_id" ]] && return

  "$herdr" workspace report-metadata "$workspace_id" \
    --source "$source_id" \
    --token "opencode_session=$session_id" >/dev/null
}

cache_workspace() {
  local workspace_id=$1 panes pane pane_rows status=0

  panes=$("$herdr" pane list --workspace "$workspace_id") || return 1
  pane_rows=$(jq -c --arg workspace_id "$workspace_id" '
    .result.panes[]? |
    select(.workspace_id == $workspace_id and .agent_session.agent == "opencode")
  ' <<<"$panes") || return 1
  while IFS= read -r pane; do
    [[ -n $pane ]] || continue
    cache_pane "$pane" || status=1
  done <<<"$pane_rows"
  return "$status"
}

if [[ ${1:-} == --all ]]; then
  snapshot=$("$herdr" api snapshot) || exit
  pane_rows=$(jq -c '
    .result.snapshot.panes[]? | select(.agent_session.agent == "opencode")
  ' <<<"$snapshot") || exit 1
  status=0
  while IFS= read -r pane; do
    [[ -n $pane ]] || continue
    cache_pane "$pane" || status=1
  done <<<"$pane_rows"
  exit "$status"
fi

if [[ ${1:-} == --workspace ]]; then
  [[ -n ${2:-} ]] || {
    echo "--workspace requires a workspace ID" >&2
    exit 2
  }
  cache_workspace "$2"
  exit
fi

event=${HERDR_PLUGIN_EVENT_JSON:-}
[[ -n $event ]] || exit
pane=$(jq -c '.data.pane // empty' <<<"$event")
if [[ -z $pane ]]; then
  pane_id=${HERDR_PANE_ID:-$(jq -r '.data.pane_id // empty' <<<"$event")}
  [[ -n $pane_id ]] || exit
  pane=$("$herdr" pane get "$pane_id" 2>/dev/null | jq -c '.result.pane // empty')
fi
[[ -n $pane ]] || exit
cache_pane "$pane"

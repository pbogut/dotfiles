#!/usr/bin/env bash

herdr=${HERDR_BIN_PATH:-herdr}
source_id="plugin:${HERDR_PLUGIN_ID:-pbogut.repo-metadata}"

cache_pane() {
  local pane=$1
  local workspace_id session_id current

  [[ $(jq -r '.agent_session.agent // empty' <<<"$pane") == opencode ]] || return
  [[ $(jq -r '.agent_session.source // empty' <<<"$pane") == herdr:opencode ]] || return
  [[ $(jq -r '.agent_session.kind // empty' <<<"$pane") == id ]] || return

  workspace_id=$(jq -r '.workspace_id // empty' <<<"$pane")
  session_id=$(jq -r '.agent_session.value // empty' <<<"$pane")
  [[ -n $workspace_id && $session_id =~ ^[A-Za-z0-9._:-]{1,80}$ ]] || return

  current=$("$herdr" workspace get "$workspace_id" 2>/dev/null |
    jq -r '.result.workspace.tokens.opencode_session // empty')
  [[ $current == "$session_id" ]] && return

  "$herdr" workspace report-metadata "$workspace_id" \
    --source "$source_id" \
    --token "opencode_session=$session_id" >/dev/null
}

if [[ ${1:-} == --all ]]; then
  snapshot=$("$herdr" api snapshot) || exit
  while IFS= read -r pane; do
    cache_pane "$pane"
  done < <(jq -c '.result.snapshot.panes[] | select(.agent_session.agent == "opencode")' <<<"$snapshot")
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

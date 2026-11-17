# A kept core terminal restarts as a shell after process loss. Check once at
# its first prompt, where we can replace that shell without typing into it.
if [[ -n ${HC_TERMINAL_ID:-} ]]; then
  autoload -Uz add-zsh-hook
  _herdr_app_opencode_recover() {
    add-zsh-hook -d precmd _herdr_app_opencode_recover
    local result
    result=$(herdr-app-opencode --recover "$$") || return
    local -a target=("${(@0)result}")
    (( ${#target} == 3 )) || return
    cd -- "$target[3]" || return
    HERDR_APP_SPACE_ID=$target[1] exec herdr-app-opencode --start "$target[2]"
  }
  add-zsh-hook precmd _herdr_app_opencode_recover
fi

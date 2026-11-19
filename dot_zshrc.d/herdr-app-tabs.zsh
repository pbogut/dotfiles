# Recover a registered program once, from Core's replacement root shell.
if [[ -n ${HC_TERMINAL_ID:-} ]]; then
  autoload -Uz add-zsh-hook
  _herdr_app_tabs_recover() {
    add-zsh-hook -d precmd _herdr_app_tabs_recover
    local result
    result=$(herdr-app-tab --recover "$$") || return
    local -a target=("${(@0)result}")
    (( ${#target} >= 5 )) || return
    cd -- "$target[1]" || exit
    HERDR_APP_HOME=$target[2] HERDR_APP_SPACE_ID=$target[3] \
      exec herdr-app-tab --start "$target[-1]" "${(@)target[4,-2]}"
  }
  add-zsh-hook precmd _herdr_app_tabs_recover
fi

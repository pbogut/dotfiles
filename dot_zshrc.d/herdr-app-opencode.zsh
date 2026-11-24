if [[ -n ${HC_TERMINAL_ID:-} ]]; then
  autoload -Uz add-zsh-hook
  # The TUI touches this flag only when it has a session to recover. Ordinary
  # prompts need no Core RPC. The durable session and folder live on the terminal.
  export HERDR_APP_OC_PROMPT_FLAG=${XDG_RUNTIME_DIR:-${TMPDIR:-/tmp}}/herdr-oc-$$-${RANDOM}-${RANDOM}
  _herdr_app_opencode_returned() {
    [[ -f $HERDR_APP_OC_PROMPT_FLAG ]] || return 0
    command hc label "$HC_TERMINAL_ID" pbogut.oc.resume-dir= >/dev/null &&
      command rm -f -- "$HERDR_APP_OC_PROMPT_FLAG"
    return 0
  }
  _herdr_app_opencode_recover() {
    add-zsh-hook -d precmd _herdr_app_opencode_recover
    local result
    result=$(herdr-app-opencode --recover "$$") || return
    local -a target=("${(@0)result}")
    case $target[1] in
      slot)
        cd -- "$target[4]" || return
        HERDR_APP_SPACE_ID=$target[2] exec herdr-app-opencode --start "$target[3]"
        ;;
      shell)
        cd -- "$target[3]" || return
        command env -u HERDR_ENV -u HERDR_PANE_ID -u HERDR_SOCKET_PATH -u HERDR_TAB_ID -u HERDR_WORKSPACE_ID \
          opencode --session "$target[2]"
        _herdr_app_opencode_returned
        ;;
    esac
  }
  add-zsh-hook precmd _herdr_app_opencode_returned
  add-zsh-hook precmd _herdr_app_opencode_recover
fi

#=================================================
# name:   prompt.zsh
# author: Pawel Bogut <https://pbogut.me>
# date:   25/06/2018
#=================================================
GIT_BRANCH=$'$(__git_ps1 " %s ")'
VIMODE_COLOR="003"

vim_ins_short="%K{003}%B%F{0} I%k%b%{$reset_color%}"
vim_cmd_short="%K{014}%B%F{0} N%k%b%{$reset_color%}"
vim_vis_short="%K{005}%B%F{0} V%k%b%{$reset_color%}"

HOST_COLOR="%F{012}"
if [ -n "$SSH_CLIENT"  ] || [ -n "$SSH_TTY"  ]; then
  HOST_COLOR="%F{003}"
fi

vim_ps1() {
  USERHOST="%B%F{001}[%b%k%(!.%F{001}.%F{012})%n%F{001}@${HOST_COLOR}%M%B%F{001}]%b"
  if [[ $LAST_EXIT_CODE == 0 ]]; then
    ERROR_COLOR="%F{002}"
    ERROR_CODE=""
  else
    ERROR_COLOR="%F{001}"
    ERROR_CODE=" [ ERROR $LAST_EXIT_CODE ]"
  fi
  TIME="${ERROR_COLOR}[$(date +'%H:%M:%S %Y-%m-%d')]${ERROR_CODE}"
  PS1="$USERHOST %B%F{001}(%b%F{012}%~%B%F{001}) %b%F{004}${GIT_BRANCH}%f${TIME}
${VIMODE_LETTER}%F{${VIMODE_COLOR}} %B%F{001}%(!.#.λ) %b%f%k"
}
precmd() {
  LAST_EXIT_CODE=$?
  # RPROMPT=$vim_ins_mode && VIMODE_COLOR="003"
  VIMODE_LETTER=$vim_ins_short && VIMODE_COLOR="003"
  vim_ps1
  # set title
  print -Pn "\e]0;%n@%m:%~\a"
}
preexec() {
  print -Pn "\033]0;%n@%m:$1:%~\a\007"
}
zle-keymap-select() {
  VIMODE_LETTER=$vim_ins_short && VIMODE_COLOR="003"
  [[ $KEYMAP = vicmd ]] && VIMODE_LETTER=$vim_cmd_short && VIMODE_COLOR="014"
  [[ $KEYMAP = vivis ]] && VIMODE_LETTER=$vim_vis_short && VIMODE_COLOR="005"
  vim_ps1
  zle reset-prompt
}
zle-line-init() {
  VIMODE_COLOR="003" && vim_ps1
  typeset -g __prompt_status="$?"
}

noop () {
  return
}

zle -N noop
bindkey -M vicmd '\e' noop

zle -N zle-keymap-select
zle -N zle-line-init
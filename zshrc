# Lines configured by zsh-newuser-install
HISTFILE=~/.histfile
HISTSIZE=1000
SAVEHIST=1000
setopt appendhistory autocd extendedglob nomatch ignoreeof
set -o shwordsplit
unsetopt beep
#colors
autoload -U colors && colors

# The following lines were added by compinstall
zstyle :compinstall filename '~/.zshrc'
zstyle ':completion:*' menu select

autoload -Uz compinit
compinit

lazy_source () {
    eval "$1 () { [ -f $2 ] && source $2 && $1 \$@ }"
}

# End of lines added by compinstall
# Load all files from .shell/zshrc.d directory
if [ -d $HOME/.zshrc.d ]; then
  for file in $HOME/.zshrc.d/*.zsh; do
    source $file
  done
fi

# Prompt
BGREEN=$'%{\e[1;32m%}'
GREEN=$'%{\e[0;32m%}'
BRED=$'%{\e[1;31m%}'
RED=$'%{\e[0;31m%}'
BBLUE=$'%{\e[1;34m%}'
BLUE=$'%{\e[0;34m%}'
NORMAL=$'%{\e[00m%}'

#vim mode
setopt transientrprompt
bindkey -v

export KEYTIMEOUT=1

bindkey '^P' up-history
bindkey '^N' down-history
bindkey '^?' backward-delete-char
bindkey '^h' backward-delete-char
bindkey '^w' backward-kill-word
bindkey '^r' history-incremental-search-backward
bindkey '^j' history-beginning-search-forward
bindkey '^k' history-beginning-search-backward
bindkey '^[j' history-beginning-search-forward
bindkey '^[k' history-beginning-search-backward

# vim_ins_mode="%F{022}%K{022}%B%F{255} INSERT %k%b%{$reset_color%}"
# vim_cmd_mode="%F{027}%K{027}%B%F{255} NORMAL %k%b%{$reset_color%}"
# vim_vis_mode="%F{088}%K{088}%B%F{255} VISUAL %k%b%{$reset_color%}"
# solarized colors
vim_ins_mode="%F{003}%K{003}%B%F{255} INSERT %k%b%{$reset_color%}"
vim_cmd_mode="%F{014}%K{014}%B%F{255} NORMAL %k%b%{$reset_color%}"
vim_vis_mode="%F{005}%K{005}%B%F{255} VISUAL %k%b%{$reset_color%}"

GIT_BRANCH=$'$(__git_ps1 "(%s)")'

VIMODE_COLOR="003"
vim_ps1() {
  PS1="%B%F{001}(%b%F{012}%~%B%F{001}) %b%F{004}${GIT_BRANCH}%f
%F{${VIMODE_COLOR}} %k%(!.%F{001}.%F{012})%n%F{001}@${HOST_COLOR}%M %B%F{001}%(!.#.$) %b%f%k"
}
precmd() {
  RPROMPT=$vim_ins_mode && VIMODE_COLOR="003"
  vim_ps1
}
zle-keymap-select() {
  RPROMPT=$vim_ins_mode && VIMODE_COLOR="003"
  [[ $KEYMAP = vicmd ]] && RPROMPT=$vim_cmd_mode && VIMODE_COLOR="014"
  [[ $KEYMAP = vivis ]] && RPROMPT=$vim_vis_mode && VIMODE_COLOR="005"
  vim_ps1
  zle reset-prompt
}
zle-line-init() {
  VIMODE_COLOR="003" && reload_ps1
  typeset -g __prompt_status="$?"
}

noop () { }

zle -N noop
bindkey -M vicmd '\e' noop

zle -N zle-keymap-select
zle -N zle-line-init

# End of lines configured by zsh-newuser-install

# create a zkbd compatible hash;
# to add other keys to this hash, see: man 5 terminfo
typeset -A key

key[Home]=${terminfo[khome]}
key[End]=${terminfo[kend]}
key[Insert]=${terminfo[kich1]}
key[Delete]=${terminfo[kdch1]}
key[Up]=${terminfo[kcuu1]}
key[Down]=${terminfo[kcud1]}
key[Left]=${terminfo[kcub1]}
key[Right]=${terminfo[kcuf1]}
key[PageUp]=${terminfo[kpp]}
key[PageDown]=${terminfo[knp]}

# setup key accordingly
[[ -n "${key[Home]}"     ]]  && bindkey  "${key[Home]}"     beginning-of-line
[[ -n "${key[End]}"      ]]  && bindkey  "${key[End]}"      end-of-line
[[ -n "${key[Insert]}"   ]]  && bindkey  "${key[Insert]}"   overwrite-mode
[[ -n "${key[Delete]}"   ]]  && bindkey  "${key[Delete]}"   delete-char
[[ -n "${key[Up]}"       ]]  && bindkey  "${key[Up]}"       history-beginning-search-backward
[[ -n "${key[Down]}"     ]]  && bindkey  "${key[Down]}"     history-beginning-search-forward
[[ -n "${key[Left]}"     ]]  && bindkey  "${key[Left]}"     backward-char
[[ -n "${key[Right]}"    ]]  && bindkey  "${key[Right]}"    forward-char
[[ -n "${key[PageUp]}"   ]]  && bindkey  "${key[PageUp]}"   beginning-of-buffer-or-history
[[ -n "${key[PageDown]}" ]]  && bindkey  "${key[PageDown]}" end-of-buffer-or-history

# Finally, make sure the terminal is in application mode, when zle is
# active. Only then are the values from $terminfo valid.
if (( ${+terminfo[smkx]} )) && (( ${+terminfo[rmkx]} )); then
    function zle-line-init () {
        printf '%s' "${terminfo[smkx]}"
    }
    function zle-line-finish () {
        printf '%s' "${terminfo[rmkx]}"
    }
    zle -N zle-line-init
    zle -N zle-line-finish
fi

alias ls="ls --color=auto"
alias fix_terminal="stty sane"
alias ssh-weechat="ssh smeagol@weechat.pbogut.me -t LC_ALL=en_GB.utf8 screen -U -D -RR weechat weechat"

alias php_debug_on="export XDEBUG_CONFIG=\"idekey=PHPSTORM\""
alias php_debug_off="export XDEBUG_CONFIG="
alias ctags_php="ctags -h \".php\" -R --exclude=\".git\" --exclude=\"tests\" --exclude=\"*.js\" --PHP-kinds=+cf"

alias update="yaourt -Syu --aur"

alias tunelssh_pl="sshuttle --dns -vr root@46.41.130.28 0/0"
alias tunelssh_de="sshuttle --dns -vr smeagol@smeagol.pl:59184 0/0"

alias yaourt-ignore-pgp="yaourt --m-arg \"--skipchecksums --skippgpcheck\""

# shortcuts
alias e="exit"
alias m="ncmpcpp"
# exit shell after closing ncmpcpp
alias mq="ncmpcpp && exit"

# rlwrap aliases to get vi like input, thats just awesome
if type rlwrap > /dev/null; then
  alias iex="rlwrap -a iex"
fi

tmux() { if [[ $1 == "-ss"  ]]; then command tmuxss.sh "$2"; else command tmux "$@"; fi; }

#local configs
if [ -f ~/.profile ]; then
  source ~/.profile
fi
if [ -f ~/.localsh ]; then
  source ~/.localsh
fi

export PATH="$PATH:$HOME/bin:$HOME/.bin:$HOME/.scripts"

#git branch in prompt
setopt prompt_subst
HOST_COLOR="%F{012}"
#ssh session settings
if [ -n "$SSH_CLIENT"  ] || [ -n "$SSH_TTY"  ]; then
  #diferent host color when ssh
  HOST_COLOR="%F{003}"
  #default tmux bind when ssh (so I can use it remotly and localy)
  tmux unbind C-a 2>&1 > /dev/null
  tmux set -g prefix C-b 2>&1 > /dev/null
  tmux bind C-b send-prefix 2>&1 > /dev/null
fi
# export RPROMPT=$'$(__git_ps1 "%s")'
export rvmsudo_secure_path=1
export PATH="$PATH:$HOME/.rvm/bin"
export PATH="$PATH:$HOME/.composer/vendor/bin"

# make colors compatibile with tmux
export TERM=xterm-256color
if [[ ! -z "$TMUX"  ]]; then
  export ZLE_RPROMPT_INDENT=0
fi

# default editor
if ! type "nvim" > /dev/null; then
  export EDITOR=vim
else
  export EDITOR=nvim
  alias vim="nvim"
fi

# chruby
[[ -s "/usr/local/share/chruby/chruby.sh" ]] && . "/usr/local/share/chruby/chruby.sh"
# its slow as hell and I'm not using it too offen, so lazy loading should be fine
export NVM_DIR="$HOME/.nvm"
lazy_source nvm "$NVM_DIR/nvm.sh"
alias myip=wget http://ipinfo.io/ip -qO -
alias myip="wget http://ipinfo.io/ip -qO -"

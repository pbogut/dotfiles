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


vim_ins_mode="%F{022}%K{022}%B%F{255} INSERT %k%b%{$reset_color%}"
vim_cmd_mode="%F{027}%K{027}%B%F{255} NORMAL %k%b%{$reset_color%}"
vim_vis_mode="%F{088}%K{088}%B%F{255} VISUAL %k%b%{$reset_color%}"

precmd() {
  RPROMPT=$vim_ins_mode
}
zle-keymap-select() {
  RPROMPT=$vim_ins_mode
  [[ $KEYMAP = vivis ]] && RPROMPT=$vim_vis_mode
  () { return $__prompt_status }
  [[ $KEYMAP = vicmd ]] && RPROMPT=$vim_cmd_mode
  () { return $__prompt_status }
  zle reset-prompt
}
zle-line-init() {
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
#[[ -n "${key[Up]}"       ]]  && bindkey  "${key[Up]}"       up-line-or-history
#[[ -n "${key[Down]}"     ]]  && bindkey  "${key[Down]}"     down-line-or-history
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

alias ls="ls --color"
alias e="exit"
alias fix_terminal="stty sane"
alias ssh-weechat="ssh smeagol@weechat.pbogut.me -t LC_ALL=en_GB.utf8 screen -U -D -RR weechat weechat"

alias php_debug_on="export XDEBUG_CONFIG=\"idekey=PHPSTORM\""
alias php_debug_off="export XDEBUG_CONFIG="
alias ctags_php="ctags -h \".php\" -R --exclude=\".git\" --exclude=\"tests\" --exclude=\"*.js\" --PHP-kinds=+cf"

alias update="yaourt -Syu --aur"

alias tunelssh_pl="sshuttle --dns -vr root@46.41.130.28 0/0"
alias tunelssh_de="sshuttle --dns -vr smeagol@smeagol.pl:59184 0/0"

alias yaourt-ignore-pgp="yaourt --m-arg \"--skipchecksums --skippgpcheck\""

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

export PATH="$PATH:./bin:$HOME/bin:/usr/lib/perl5/vendor_perl/bin:$HOME/bin/scripts"

#git branch in prompt
setopt prompt_subst
HOST_COLOR="${BGREEN}"
if [ -n "$SSH_CLIENT"  ] || [ -n "$SSH_TTY"  ]; then
  HOST_COLOR="%F{226}"
fi
# export RPROMPT=$'$(__git_ps1 "%s")'
GIT_BRANCH=$'$(__git_ps1 "(%s)")'
PS1="${BRED}(${NORMAL}%~${BRED}) ${BBLUE}${GIT_BRANCH}
%(!.${BRED}.${BGREEN})%n${BRED}@${HOST_COLOR}%M ${BRED}%(!.#.$)${NORMAL}%f%b%k "


export PATH="$PATH:$HOME/.rvm/bin" # Add RVM to PATH for scripting
export rvmsudo_secure_path=1
export PATH="$HOME/.npm/bin:$PATH"
export PATH="$PATH:$HOME/.scripts"
export PATH="$PATH:$HOME/.composer/vendor/bin"

# export TERM=xterm-256color
# make colors compatibile with tmux
export TERM=screen-256color
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
# always create/attach tmux session
[[ $- != *i*  ]] && return


export NVM_DIR="/home/pbogut/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"  # This loads nvm

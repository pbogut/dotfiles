# Lines configured by zsh-newuser-install
HISTFILE=~/.histfile
HISTSIZE=10000
SAVEHIST=10000
setopt appendhistory autocd extendedglob nomatch ignoreeof interactivecomments \
       append_history extended_history hist_expire_dups_first hist_ignore_dups \
       hist_ignore_all_dups hist_ignore_space hist_verify inc_append_history   \
       share_history

set -o shwordsplit
unsetopt beep
stty -ixon # disable c-s and c-q (terminal flow)
#colors
autoload -U colors && colors

# The following lines were added by compinstall
zstyle :compinstall filename '~/.zshrc'
zstyle ':completion:*' menu select
zstyle ':completion:*' rehash true

autoload -Uz compinit
compinit
lazy_source () {
    eval "$1 () { [ -f $2 ] && source $2 && $1 \$@ }"
}

# End of lines added by compinstall
hostname=`hostname`
# Load all files from .shell/zshrc.d directory
if [ -d $HOME/.zshrc.d ]; then
  for file in $HOME/.zshrc.d/*.zsh; do
    source $file
  done
  export FPATH="$FPATH:$HOME/.zshrc.d/functions"
  for file in "$HOME/.zshrc.d/functions/"*; do
    autoload -Uz "$(basename "$file")"
  done
fi
# cdr already exists in zsh apparently, so override right away
source $HOME/.zshrc.d/functions/cdr

bindkey -e

# bash word style (c-w on /some/path| will results in /some/|)
autoload -U select-word-style && select-word-style bash

export KEYTIMEOUT=1
bindkey '^P' up-history
bindkey '^N' down-history
bindkey '^?' backward-delete-char
bindkey '^h' backward-delete-char
bindkey '^d' delete-char
bindkey '^w' backward-kill-word
bindkey '^r' history-incremental-search-backward
bindkey '^j' history-beginning-search-forward
bindkey '^k' history-beginning-search-backward
bindkey '^[j' history-beginning-search-forward
bindkey '^[k' history-beginning-search-backward

# rsi
bindkey '^a' beginning-of-line
bindkey '^e' end-of-line
bindkey '^f' forward-char
bindkey '^b' backward-char
bindkey '^[f' forward-word
bindkey '^[b' backward-word

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

# ctrl-v to edit command line in $EDITOR
autoload -z edit-command-line
zle -N edit-command-line
bindkey "^V" edit-command-line

eval `dircolors ~/.config/dircolors-solarized/dircolors.256dark`

abbrev-alias --init
abbrev-alias -g G='|rg'
abbrev-alias -g dc='docker-compose'

# shortcuts
source ~/.aliases

if [[ -f ~/.fzf.zsh ]]; then
  source ~/.fzf.zsh
fi

if [[ -f ~/.opam/opam-init/init.zsh ]]; then
  source /home/pbogut/.opam/opam-init/init.zsh  > /dev/null 2> /dev/null
fi

if [[ -f ~/.zshrc.d/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh ]]; then
  source ~/.zshrc.d/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
  export ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=240"
  export ZSH_AUTOSUGGEST_BUFFER_MAX_SIZE=20
fi

setopt prompt_subst
# starship prompt
source <(/usr/bin/starship init zsh --print-full-init 2>/dev/null)

# host specific config
if [ -f $HOME/.$hostname.zsh ]; then
  source $HOME/.$hostname.zsh
fi

eval "$(rtx activate zsh 2>/dev/null)"
alias asdf="rtx"

alias luamake=/home/pbogut/.gitpac/sumneko/lua-language-server/3rd/luamake/luamake


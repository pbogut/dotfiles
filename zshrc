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

eval `dircolors ~/.config/dircolors-solarized/dircolors.256dark`

alias se="sudoedit"

alias ls="ls --color=auto"
alias ll="ls -lhA --color=auto"
alias pacman="pacman --color=auto"
alias ssh-weechat="ssh smeagol@weechat.pbogut.me -t LC_ALL=en_GB.utf8 screen -U -D -RR weechat weechat"

notes() {
    if [ ! -z $1 ];then
        $(which $EDITOR) ~/Notes/ +"Note $@"
    else
        note=$(find $HOME/Notes/ | sed "s#^$HOME/Notes/##" | grep -v '^$' | fzf)
        if [[ ! -z $note ]];then
            $(which $EDITOR) ~/Notes/ +"Note $note"
        fi
    fi
}
dirdiff() {
  if [[ -z  $2 ]]; then
    echo "Usage: dirdiff /path/to/dir/one /path/to/dir/two"
  else
    echo ":bw! | DirDiff $1 $2" | $(which $EDITOR) $TMP/skip_session
  fi
}

alias xo="xdg-open"
alias ro="rifle" #rifle open
alias so="source"
alias clone="~/.scripts/term-in-current-dir.sh"
alias c="clone"

alias mutt="LC_ALL=en_GB.utf8 screen -U -D -RR mutt mutt"
alias ncmpcpp="LC_ALL=en_GB.utf8 screen -U -D -RR ncmpcpp ncmpcpp -p $MOPIDY_PORT"

alias php_debug_on="export XDEBUG_CONFIG=\"idekey=PHPSTORM\""
alias php_debug_off="export XDEBUG_CONFIG="
alias ctags_php="ctags -h \".php\" -R --exclude=\".git\" --exclude=\"tests\" --exclude=\"*.js\" --PHP-kinds=+cf"

alias update="yaourt -Syu --aur"

alias tunnelssh_gb="sshuttle --dns -vr centipede.pbogut.me 0/0"

# rifle open ask
roa() {
  if [[ -z $2 ]] && [[ `/usr/bin/rifle -l "$1" | wc -l` -gt 1 ]]; then
      /usr/bin/rifle -l "$1" | fzf | sed 's/\([0-9]*\).*/\1/' | xargs /usr/bin/rifle "$1" -p
  else
    /usr/bin/rifle "$@"
  fi
}

# shortcuts
alias sc="bash -c \"\`cat ~/.commands | fzf | sed 's,[^;]*;;; ,,'\`\""
alias q="exit"
alias :q="exit"
alias m="ncmpcpp"
alias i="ssh-weechat"
alias e="mutt"
alias vssh="vagrant ssh"
alias vup="vagrant up"

# rlwrap aliases to get vi like input, thats just awesome
# note that completion wont work with rlwrap
if type rlwrap > /dev/null; then
  alias viex="rlwrap -a iex"
fi
# autocomplete in irb
alias irb="irb -r 'irb/completion'"

#local configs
if [ -f ~/.profile ]; then
  source ~/.profile
fi
if [ -f ~/.fzf.zsh ]; then
  source ~/.fzf.zsh
fi

setopt prompt_subst

[[ -f /usr/lib/libstderred.so ]] && export LD_PRELOAD="/usr/lib/libstderred.so${LD_PRELOAD:+:$LD_PRELOAD}"

# make colors compatibile with tmux
export TERM=xterm-256color

export FZF_DEFAULT_OPTS="
  --filepath-word --reverse
  --bind=ctrl-e:preview-down,ctrl-y:preview-up,ctrl-s:toggle-preview
  --bind=ctrl-w:backward-kill-word
  --height 40%
  --cycle
  "

alias qvim=nvim-qt
# default editor
if type "nvim" > /dev/null; then
  alias vim=nvim
  export EDITOR=nvim
else
  export EDITOR=vim
fi
export PAGER="less"
export TERMINAL="urxvt"
# golang
export GOPATH="$HOME/.gocode"
# chruby
[[ -s "/usr/local/share/chruby/chruby.sh" ]] && . "/usr/local/share/chruby/chruby.sh"
# its slow as hell and I'm not using it too offen, so lazy loading should be fine
export NVM_DIR="$HOME/.nvm"
lazy_source nvm "$NVM_DIR/nvm.sh"
alias myip="wget http://ipinfo.io/ip -qO -"

# host specific config
if [ -f $HOME/.$hostname.zsh ]; then
  source $HOME/.$hostname.zsh
fi

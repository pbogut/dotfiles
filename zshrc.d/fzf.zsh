#!/bin/bash
#=================================================
# name:   fzf.zsh
# author: Pawel Bogut <pbogut@ukpos.com> <http://pbogut.me>
# date:   03/02/2017
#
# Based on:
# https://www.reddit.com/r/vim/comments/3f0zbg/psa_if_youre_using_ctrlp_use_this_maintained_fork/
#=================================================

# fzf config
export FZF_DEFAULT_OPTS="
  --filepath-word --reverse
  --bind=ctrl-e:preview-down,ctrl-y:preview-up,ctrl-s:toggle-preview
  --bind=ctrl-w:backward-kill-word
  --height 40%
  --cycle
  "

fe() {
    # fe - Open the selected files with the default editor
    local files=$(fzf --query="$1" --select-1 --exit-0 | sed -e "s/\(.*\)/\'\1\'/")
    local command="${EDITOR:-vim} -p $files"
    [ -n "$files" ] && eval $command
}

cdf() {
    local start_dir query dir
    if [[ -d $1 ]];then
        start_dir=$1
        query="${@:2}"
    else
        query="$@"
    fi
    dir=$(find ${start_dir:-*} -path '*/\.*' -prune -o -type d -print 2> /dev/null | fzf +m -q "$query") &&
    # cdf - cd to selected directory
    cd "$dir"
}

fh() {
    # fh - repeat history
    eval $( ([ -n "$ZSH_NAME" ] && fc -l 1 || history) | fzf +s --tac | sed 's/ *[0-9]* *//')
}

fkill() {
    # fkill - kill process
    pid=$(ps -ef | grep "^$USER" | sed 1d | fzf -m | awk '{print $2}')
    if [ "x$pid" != "x" ]
    then
        kill -${1:-9} $pid
    fi
}

sufkill() {
    # fkill - kill process
    pid=$(ps -ef | sed 1d | fzf -m | awk '{print $2}')
    if [ "x$pid" != "x" ]
    then
        sudo kill -${1:-9} $pid
    fi
}

# anamnesis clipboard fuzy lookup
fclip() {
    anamnesis.sh list | fzf | anamnesis.sh to_clip
}

#porjects
cdp() {
    project=$(ls-project | fzf -q "$1")
    if [[ ! $project == "" ]]; then
        cd "$HOME/projects/$project"
    fi
}

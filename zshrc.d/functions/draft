#!/bin/bash
#=================================================
# name:   vimdraft.zsh
# author: Pawel Bogut <pbogut@ukpos.com> <http://pbogut.me>
# date:   24/05/2017
#=================================================
draft() {
    ext=${1:-md}
    cd ~/Drafts
    rand=$(head -n1 /dev/urandom | sha256sum | sed 's,^\(.\{8\}\).*,\1,g')
    file="$(date +'%Y-%m-%d_%H:%M:%S')_$rand.$ext"
    nvim $file
    cd -
}

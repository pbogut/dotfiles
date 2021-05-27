#!/bin/bash
#=================================================
# name:   notmuch-archive-link.sh
# author: Pawel Bogut <https://pbogut.me>
# date:   09/12/2020
#=================================================
find $HOME/Maildir -iname '*.archive' -type d | while read source; do
    dest=/storage/nextcloud/Maildir.archive${source##$HOME/Maildir}
    destdir=$(dirname $dest)
    echo mkdir -p $destdir
    mkdir -p $destdir
    echo mv $source $dest
    mv $source $dest
    echo ln -s $dest $source
    ln -s $dest $source
done

find $HOME/Nextcloud/Maildir.archive/* -iname '*.archive' -type d | while read source; do
    dest=$HOME/Maildir${source##$HOME/Nextcloud/Maildir.archive}
    ln -sf $source $dest
done

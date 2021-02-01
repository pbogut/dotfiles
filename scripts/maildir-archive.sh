#!/bin/bash
#=================================================
# name:   maildir-archive.sh
# author: Pawel Bogut <https://pbogut.me>
# date:   11/12/2020
#=================================================

find ~/Maildir -maxdepth 1 -type d -not -name '.*' -not -name 'Maildir' | while read fulldir; do
  accountdir=$(basename $fulldir)
  tar czvf /storage/nextcloud/Maildir.archive/$accountdir.tgz --exclude=\*.archive $fulldir
done

#!/bin/bash
#=================================================
# name:   maildir-archive.sh
# author: Pawel Bogut <https://pbogut.me>
# date:   11/12/2020
#=================================================
tmparchive="/storage/tmp/maildir-archive"
mkdir -p "$tmparchive"
rm -fr "${tmparchive:?}/"*

find ~/Maildir -maxdepth 1 -type d -not -name '.*' -not -name 'Maildir' | while read -r fulldir; do
  accountdir="$(basename "$fulldir")"
  archivepath="$tmparchive/$accountdir-current.tgz"
  tar czvf "$archivepath" --exclude=\*.archive "$fulldir"
done

find ~/Maildir -mindepth 1 -maxdepth 2 -type d -name '*.archive' | while read -r fulldir; do
  accountdir="$(basename "$(dirname "$fulldir")")"
  archivepath="$tmparchive/$accountdir-archive.tar"
  if [[ -f "$archivepath" ]]; then
    tar rvf "$archivepath" "$fulldir"
  else
    tar cvf "$archivepath" "$fulldir"
  fi
done

mv "${tmparchive:?}"/* /storage/nextcloud/Maildir/

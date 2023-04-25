#!/usr/bin/env bash
tmp_file=$(mktemp)
cat /dev/stdin > $tmp_file
set -e
set -o pipefail

from=$(exail -f "$tmp_file" --from-email)
acc=${from##*@}

# mutt-pre-process.rb -- adds html version of email using markdown
# mutt-put-on-imap.rb -- puts copy of email on the imap server
# mutt-add-tracking-pixel.rb -- adds tracking pixel
# (because pixel is added after email is placed on imap server,
#  you wont triger pixel event yourself)

if [[ $1 == "--preview" ]]; then
    preview="$(mktemp -d)/email.html"
    cat $tmp_file | mutt-pre-process.rb --html-only > $preview
    browser $preview > /dev/null 2>&1
    exit 1
fi

cat $tmp_file |
    mutt-pre-process.rb |
    mutt-put-on-imap.rb |
    mutt-add-tracking-pixel.rb |
    msmtp -a $acc --passwordeval="config email/$from/pass" --user=`config email/$from/user $from` --from=$from ${@:1}

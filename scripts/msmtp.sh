#!/bin/sh
tmp_file=$(mktemp)
cat /dev/stdin > $tmp_file
set -e
set -o pipefail

from=$(cat $tmp_file |
    grep '^From: ' | head -n1 |
    sed 's,From: [^<]*<\(.*\)>,\1,' |
    sed 's,From: \([^\s]*\),\1,')
acc=$(echo $from | sed 's,.*@,,')

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

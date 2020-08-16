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

cat $tmp_file |
    mutt-html-mime.rb |
    msmtp -a $acc --passwordeval="gpg-config get email-$from-passwd" --user=`gpg-config get email-$from-user` --from=$from ${@:1}


echo $tmp_file > /tmp/__email_file
echo $from >> /tmp/__email_var
echo $acc >> /tmp/__email_var
echo msmtp -a $acc --passwordeval="gpg-config get email-$from-passwd" --user=`gpg-config get email-$from-user` --from=$from ${@:1} >> /tmp/__email_var

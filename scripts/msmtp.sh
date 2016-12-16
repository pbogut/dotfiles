#!/bin/sh
cat /dev/stdin | msmtp -a $1 --passwordeval="~/.scripts/get-config.sh email-$1-passwd" --user=`~/.scripts/get-config.sh email-$1-user` --from=`~/.scripts/get-config.sh email-$1-from` ${@:2}

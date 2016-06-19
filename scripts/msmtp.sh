#!/bin/sh
cat /dev/stdin | msmtp -a $1 --passwordeval="get-config.sh gemail-$1-passwd" --user=`get-config.sh email-$1-user` --from=`get-config.sh email-$1-from` ${@:2}

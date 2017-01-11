#!/bin/bash
#=================================================
# name:   qb-lastpass.sh
# author: Pawel Bogut <http://pbogut.me>
# date:   10/01/2017
#=================================================
jseval() {
    echo "$1" | while read l; do
        echo "jseval $l" >> $QUTE_FIFO;
    done;
}

site_url=$QUTE_URL
site_url=${site_url#http*://}
site_url=${site_url#www.}
site_url=${site_url%%/*}
jseval "var __inputs = document.getElementsByTagName('input'); for(var __i = 0; __i < __inputs.length; __i++) { if (__inputs[__i].type == 'password') { var __pass = __inputs[__i]; var __user = __inputs[__i - 1]; } }; '$site_url'"

lpass show -xG "$site_url" | while read n v; do
    if [[ $n == "Username:" ]]; then
        jseval "__user.value = '$v'"
    fi
    if [[ $n == "Password:" ]]; then
        jseval "__pass.value = '$v';'*******';"
    fi
done



#!/bin/bash
#=================================================
# name:   qb-lastpass.sh
# author: Pawel Bogut <http://pbogut.me>
# date:   10/01/2017
#=================================================
# QUTE_FIFO='/tmp/elo'
jseval() {
    if [[ -n $1 ]]; then
        echo "jseval -q $1" | sed 's,//.*$,,' | tr '\n' ' ' >> $QUTE_FIFO
        echo "" >> $QUTE_FIFO
    fi
}

site_url=$QUTE_URL
site_url=${site_url#http*://}
site_url=${site_url#www.}
site_url=${site_url%%/*}

jseval "var __inputs = document.getElementsByTagName('input');
        var __candidates_p = [];
        var __candidates_u = [];
        for(var __i = 0; __i < __inputs.length; __i++) {
            if (__inputs[__i].type == 'password') {
                var __pass = __inputs[__i];
                var __user = __inputs[__i - 1];
            }
        };
        '$site_url'"


lpass show -xG "$site_url" | while read n v; do
    if [[ $n == "Username:" ]]; then
        # jseval "__user.value = '$v';"
        jseval "__candidates_u.push('$v')"
    fi
    if [[ $n == "Password:" ]]; then
        # jseval "__pass.value = '$v';'*******';"
        jseval "__candidates_p.push('$v')"
    fi
done


jseval "if (__candidates_u.length > 1) {
            var __question = [];
            for (var i=0; i<__candidates_u.length; i++) {
                __question.push((i+1) + ': ' + __candidates_u[i]);
            }
            var choice = prompt(__question.join('\\n')) - 1;
            __user.value = __candidates_u[choice];
            __pass.value = __candidates_p[choice];
        } else if (__candidates_u.length == 1) {
            __user.value = __candidates_u[0];
            __pass.value = __candidates_p[0];
        }

        delete __user;
        delete __pass;
        delete __candidates_u;
        delete __candidates_p;
        delete __question;
";

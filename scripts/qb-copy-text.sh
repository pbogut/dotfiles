#!/bin/bash
#=================================================
# name:   qb-copy-html.sh
# author: Pawel Bogut <http://pbogut.me>
# date:   11/01/2017
#=================================================
cat "$QUTE_TEXT" | xsel -i $1
if [[ $1 == '-b' ]];then
    echo "jseval 'Page text copied to clipboard'" >> $QUTE_FIFO;
elif [[ $1 == '-p' ]]; then
    echo "jseval 'Page text copied to primary selection'" >> $QUTE_FIFO;
fi

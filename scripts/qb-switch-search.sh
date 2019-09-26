#!/bin/bash
#=================================================
# name:   qutebrowser-switch-search.sh
# author: Pawel Bogut <https://pbogut.me>
# date:   28/01/2019
#=================================================
echo "$QUTE_URL" | sed -E 's,https?://(www\.)?(.*?)/.*?\?(.*$),\2 \3,' | (read domain query
    query=$(echo $query | sed -E 's,.*?q=([^&]*).*$,\1,')
    case $domain in
        duckduckgo.com)
            domain="google.com/search"
                ;;
        google.com)
            domain="duckduckgo.com/"
                ;;
        google.pl)
            domain="duckduckgo.com/"
                ;;
        google.co.uk)
            domain="duckduckgo.com/"
                ;;
    esac

    newurl="https://$domain?q=$query"
    echo "open $newurl" >> $QUTE_FIFO;
)

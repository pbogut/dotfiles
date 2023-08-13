#!/bin/bash
#=================================================
# name:   qutebrowser-switch-search.sh
# author: Pawel Bogut <https://pbogut.me>
# date:   28/01/2019
#=================================================
echo "$QUTE_URL" | sed -E 's,https?://(www\.)?(.*?)/.*?\?(.*$),\3,' | (read -r query
    query=$(echo "$query" | sed -E 's,.*?q=([^&]*).*$,\1,')
    path=$(echo "$QUTE_URL" | sed -E 's,https?://(www\.)?([^/]+)/(.*$),\3,')
    domain=$(echo "$QUTE_URL" | sed -E 's,https?://(www\.)?([^/]+)/(.*$),\2,')

    case $domain in
      protondb.com)
        domain="store.steampowered.com"
        newurl="https://$domain/$path"
        ;;
      store.steampowered.com)
        domain="protondb.com"
        newurl="https://$domain/$path"
        ;;
      duckduckgo.com)
        domain="google.com/search"
        newurl="https://$domain?q=$query"
        ;;
      search.brave.com)
        domain="google.com/search"
        newurl="https://$domain?q=$query"
        ;;
      google.com)
        domain="duckduckgo.com/"
        newurl="https://$domain?q=$query"
        ;;
      google.pl)
        domain="duckduckgo.com/"
        newurl="https://$domain?q=$query"
        ;;
      google.co.uk)
        domain="duckduckgo.com/"
        newurl="https://$domain?q=$query"
        ;;
      invidious.snopyta.org)
        domain="youtube.com/"
        newurl="https://$domain$path"
        ;;
      invidious.pbogut.me)
        domain="youtube.com/"
        newurl="https://$domain$path"
        ;;
      youtube.com)
        domain="invidious.pbogut.me/"
        newurl="https://$domain$path"
        ;;
    esac

    # newurl="https://$domain?q=$query"
    echo "open $newurl" >> $QUTE_FIFO;
)

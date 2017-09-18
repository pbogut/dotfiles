#!/bin/bash
#=================================================
# name:   i3-dmenu-web.sh
# author: Pawel Bogut <pbogut@ukpos.com> <http://pbogut.me>
# date:   30/03/2017
#=================================================
# cat ~/.rofi_web_history | rofi -dmenu -p "web:" | (
#     read query; [[ $query == "" ]] || (
#         echo $query >> ~/.rofi_web_history && \
#         cat ~/.rofi_web_history | sort | uniq > ~/.rofi_web_history.tmp && \
#         mv ~/.rofi_web_history.tmp ~/.rofi_web_history && \
#         qutebrowser_webengine "$query"
#     ) &
# )
(cat ~/.local/share/qutebrowser/history | grep -v '^[0-9]*\-r' | sort -r | while read date url name; do echo $(date -d "@${date}" '+%Y-%m-%d'
) $url; done) | uniq | rofi -dmenu -p "web:" | (
    read date query; [[ $query == "" ]] || browser "$query" &
)

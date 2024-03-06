#!/bin/bash
#=================================================
# name:   qb-url-to-remarkable.sh
# author: Pawel Bogut <https://pbogut.me>
# date:   29/11/2020
#=================================================
env > /tmp/yyyyyy
echo ':message-info "Sending website to reMarkable..."' >> $QUTE_FIFO
title=$(date +%Y_%m_%d_%H%m)_$(echo "$QUTE_TITLE" | sed 's/[^a-zA-Z0-9]/_/g')
result=$(~/.scripts/rm-print-url.sh "$QUTE_URL" "/Print" "$title")
if [[ $? == 0 ]]; then
    echo ':message-info "Sending website to reMarkable... done"' >> $QUTE_FIFO
else
    echo ':message-error "Error while sending website to reMarkable. '$result'"' >> $QUTE_FIFO
fi

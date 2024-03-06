#!/bin/bash
#=================================================
# name:   qb-url-to-remarkable.sh
# author: Pawel Bogut <https://pbogut.me>
# date:   29/11/2020
#=================================================
tmpdir=$(mktemp -d)
echo ':message-info "Generating clean pdf file..."' >> $QUTE_FIFO
title=$(date +%Y_%m_%d_%H%m)_$(echo "$QUTE_TITLE" | sed 's/[^a-zA-Z0-9]/_/g')
result=$(~/.scripts/url-to-clean-pdf.sh "$QUTE_URL" "$tmpdir" "$title")
if [[ $? == 0 ]]; then
    echo ':message-info "Generating clean pdf file... done"' >> $QUTE_FIFO
    echo ':open file://'$tmpdir/$title'.pdf' >> $QUTE_FIFO
else
    echo ':message-error "Error while generating clean pdf file. '$result'"' >> $QUTE_FIFO
fi

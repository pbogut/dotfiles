#!/bin/bash
#=================================================
# name:   qb-send-to-phone.sh
# author: Pawel Bogut <https://pbogut.me>
# date:   04/12/2020
#=================================================
api_url=$(config autotools/autoremote/api_url)
key=$(config autotools/autoremote/key)
url=$QUTE_URL

curl "$api_url" --data-urlencode "message=open-url=:=$url" --data-urlencode "key=$key"
echo ':message-info "Sent to phone"' >> $QUTE_FIFO

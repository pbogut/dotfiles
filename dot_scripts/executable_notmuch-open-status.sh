#!/bin/bash
#=================================================
# name:   notmuch-delivery-status.sh
# author: Pawel Bogut <https://pbogut.me>
# date:   14/12/2020
#=================================================
message_id=$1
encoded_id=$(echo -n "$message_id" | base64 -w 0 | sed "s,=,,g")
mutt_pipe="no"
header=""

if [[ $message_id == "" ]]; then
    echo "Provide message id"
    exit 1
fi
if [[ $message_id == "--mutt-pipe" ]]; then
    clear
    mutt_pipe="yes"
    message_id=$(enrichmail --get-message-id /dev/stdin)
    encoded_id=$(echo -n "$message_id" | base64 -w 0 | sed "s,=,,g")

    header="$header+-------------------------------------------------------\n"
    header="$header| Message-ID: $message_id\n"
    header="$header| Encoded-ID: $encoded_id\n"
    header="$header| $(notmuch search id:"$message_id")\n"
    header="$header+------------------------\n"
fi

token=$(secret email/open_tracking/token)
api_url=$(secret email/open_tracking/api_url)
data=$(curl "$api_url/rest/summary/$encoded_id" \
    --header "Auth-Token: $token" \
    --header "Accept: application/json" \
    -G -s)

echo -e "$header\n$(echo "$data" | jq -C)" | more

if [[ $mutt_pipe == "yes" ]]; then
    exit 1
fi

#!/bin/bash
#=================================================
# name:   notmuch-delivery-status.sh
# author: Pawel Bogut <https://pbogut.me>
# date:   14/12/2020
#=================================================

message_id=$1
mutt_pipe="no"
header=""

if [[ $message_id == "" ]]; then
    echo "Provide message id"
    exit 1
fi
if [[ $message_id == "--mutt-pipe" ]]; then
    clear
    mutt_pipe="yes"
    message_id=$(cat /dev/stdin |
        grep '^Message-ID: <.*>' |
        sed 's/^Message-ID: <\(.*\)>/\1/' |
        head -n1)

    echo    "+-------------------------------------------------------"
    echo -n "| "
    notmuch search id:$message_id
    echo    "+------------------------"
fi

encoded_id=$(echo -n $message_id | base64 | sed "s,=,,g")
token=$(config email/open_tracking/token)
api_url=$(config email/open_tracking/api_url)
data=$(curl "$api_url/rest/summary/$encoded_id" \
    --header "Auth-Token: $token" \
    --header "Accept: application/json" \
    -G -s)

echo $data | jq -C | more

if [[ $mutt_pipe == "yes" ]]; then
    exit 1
fi

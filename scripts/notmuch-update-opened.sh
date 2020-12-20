#!/bin/bash
#=================================================
# name:   notmuch-update-opened.sh
# author: Pawel Bogut <https://pbogut.me>
# date:   12/12/2020
#=================================================
last_sync=$HOME/.config/last_email_open_sync
last_date=$(cat $last_sync)
token=$(config email/open_tracking/token)
api_url=$(config email/open_tracking/api_url)
data=$(curl "$api_url/rest/hitlog" \
    --header "Auth-Token: $token" \
    --header "Accept: application/json" \
    --data-urlencode "from=$last_date" \
    --data-urlencode "unique=1" \
    -G -s)

count=0
echo $data | jq '.[].message_id' | while read message_id; do
    notmuch tag +opened -- id:$message_id

    summary=$(notmuch show --format=json id:$message_id |
        jq '.[0][0][0].headers' |
        jq -r '"Subject: " + .Subject, "To:      " + .To, "Date:    " + .Date')

    ipAddress=$(echo $data | jq -r ".[$count].ip_address")
    userAgent=$(echo $data | jq -r ".[$count].user_agent")

    notify-send -i mail-read "Your message has been opened:
$summary
IP:      $ipAddress
--
$userAgent"
    count=$(expr $count + 1)
done

echo $data | jq -r '.[-1].updated_at' | while read last_date; do
    if [[ -n $last_date ]] && [[ $last_date != "null" ]]; then
        echo "$last_date" >$last_sync
    fi
done

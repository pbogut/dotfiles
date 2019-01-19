#!/bin/bash
#=================================================
# name:   notmuch-checker.sh
# author: Pawel Bogut <https://pbogut.me>
# date:   18/12/2018
#=================================================
# unread="$(notmuch count -- tag:unread)"
# inbox="$(notmuch count -- tag:inbox)"
unread="$(notmuch search tag:unread | wc -l)"
inbox="$(notmuch search tag:inbox | wc -l)"
last_count_file="$TMPDIR/__notmuch_last_email_count"
last_timestamp_file="$TMPDIR/__notmuch_last_email_timestamp"
touch $last_count_file
last_count=$(cat $last_count_file)
last_timestamp=$(cat $last_timestamp_file)
echo $unread > $last_count_file

if [[ $unread == "0" ]]; then
    exit 0
fi

timestamp=$(notmuch search --format=json -- tag:unread | jq '.[0].timestamp')

if [[ "$timestamp" > "$last_timestamp" ]]; then
    message=$(notmuch search -- tag:unread |
        head -n1 |
        sed 's,thread:[a-z0-9]*\s*\(.*\) \[[^]]*\] \([^;]*\); \(.*\) (.*)$,Date:\t \1\nFrom:\t \2\nSubject: \3,')

    notify-send -i /usr/share/icons/gnome/48x48/emblems/emblem-mail.png \
        "$(echo -e "You have new message ($unread/$inbox)\n\n$message")"

    echo $timestamp > $last_timestamp_file
fi
echo $unread/$inbox

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
last_message_file="$TMPDIR/__notmuch_last_email_message"
touch $last_count_file
touch $last_message_file
last_count=$(cat $last_count_file)
last_message=$(cat $last_message_file)
echo $unread > $last_count_file

if [[ $unread == "0" ]]; then
    exit 0
fi

if [[ $last_count != $unread ]]; then
    message=$(notmuch search -- tag:unread |
        head -n1 |
        sed 's,thread:[a-z0-9]*\s*\(.*\) \[[^]]*\] \([^;]*\); \(.*\) (.*)$,Date:\t \1\nFrom:\t \2\nSubject: \3,')

    # display only if new message
    # would be better to store and cheack timestamp instead
    if [[ "$(echo $last_message)1" != "$(echo $message)" ]]; then
        notify-send -i /usr/share/icons/gnome/48x48/emblems/emblem-mail.png \
            "$(echo -e "You have new message ($unread/$inbox)\n\n$message")"
    fi
    echo $message > $last_message_file
fi
echo $unread/$inbox

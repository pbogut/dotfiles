#!/bin/bash
if [[ "$1" == "" ]]; then
    email_content="/dev/stdin"
else
    email_content="$1"
fi

query=$(cat "$email_content"      |
    sed '/^Message-ID:/I,$!d'     |   # remove everything until Message-ID
    head -n 2                     |   # get two lines in case id wrped to next
                                      # line
    sed 's/^Message-ID:[^<]*//gI' |   # remove Message-ID: label
    grep -vi '^$'                 |   # remove empty line (if actuall ID was
                                      # in second 1st will be empty)
    head -n 1                     |   # get one line only
    sed 's#[^<]*<\(.*\)>.*#\1#g'  |   # extract message id
    ruby -ne 'require "cgi"; puts CGI.escape($_)') # escape id so it fits in

(qutebrowser --target window "http://localhost:6245?q=$query" &) > /dev/null 2>&1         # open in browser

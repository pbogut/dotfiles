#!/bin/bash
if [[ "$1" == "" ]]; then
    email_content="/dev/stdin"
else
    email_content="$1"
fi

query=`cat "$email_content" | sed '/^Message-ID:/,$!d' | head -n 2 | sed 's/^Message-ID:[^<]*//g' | grep -v '^$' | sed 's#[^<]*<\(.*\)>.*#\1#g' | ruby -ne 'require "cgi"; puts CGI.escape($_)'`
chromium  "http://localhost:6245?q=$query"

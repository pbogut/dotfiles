#!/bin/bash
if [[ "$1" == "" ]]; then
    email_content="/dev/stdin"
else
    email_content="$1"
fi

query=`cat "$email_content" | grep '^Message-ID: ' | sed 's#^Message-ID: <\(.*\)>#\1#g' | ruby -ne 'require "cgi"; puts CGI.escape($_)'`
chromium  "http://localhost:6245?q=$query"

#!/bin/bash
if [[ "$1" == "" ]]; then
    email_content="/dev/stdin"
else
    email_content="$1"
fi
query=$(enrichmail --get-message-id "$email_content" | base64)
if [[ "" == "$query" ]]; then
  exit 1
fi

if [[ "$2" == "-" ]]; then
  echo "http://localhost:6245?q=$query"
else
  (gio open "http://localhost:6245?q=$query" &) > /dev/null 2>&1         # open in browser
fi


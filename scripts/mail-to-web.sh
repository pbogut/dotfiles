#!/bin/bash
if [[ "$1" == "" ]]; then
    email_content="/dev/stdin"
else
    email_content="$1"
fi
query=$(exail -f "$email_content" --message-id | base64)
if [[ "" == "$query" ]]; then
  exit 1
fi

if [[ "$2" == "-" ]]; then
  echo "http://localhost:6245?q=$query"
else
  (browser --target window "http://localhost:6245?q=$query" &) > /dev/null 2>&1         # open in browser
fi


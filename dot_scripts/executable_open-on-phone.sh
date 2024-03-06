#!/bin/bash
#=================================================
# name:   open-on-phone.sh
# author: Pawel Bogut <https://pbogut.me>
# date:   14/08/2022
#=================================================
api_url=$(secret autotools/autoremote/api_url)
key=$(secret autotools/autoremote/key)
url="$1"

curl "$api_url" --data-urlencode "message=open-url=:=$url" --data-urlencode "key=$key"

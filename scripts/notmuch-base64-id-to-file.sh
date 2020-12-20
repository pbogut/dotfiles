#!/bin/bash
#=================================================
# name:   notmuch-base64-id-to-file.sh
# author: Pawel Bogut <https://pbogut.me>
# date:   25/12/2018
#=================================================
encoded_id=$1
decoded_id=$(base64 --decode <<< $encoded_id)
notmuch search --output=files id:$decoded_id and \(tag:spam or not tag:spam\)

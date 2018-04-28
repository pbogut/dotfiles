#!/bin/bash
#=================================================
# name:   octopi-status.sh
# author: Pawel Bogut <https://pbogut.me>
# date:   25/04/2018
#=================================================
curl "$OCTOPI_URL/api/job" \
    --header "X-Api-Key: $OCTOPI_API" \
    2>/dev/null |
    jq -r '(.job.file.display) + ": " +  (.progress.completion | floor| tostring) + "%"'

#!/usr/bin/env bash
#=================================================
# name:   composer-smart
# author: Pawel Bogut <pbogut@assuredpharmacy.co.uk>
# date:   14/11/2022
#=================================================
dir="$(pwd)"
if [[ -f "$dir/composer-docker" ]]; then
    ./composer-docker "$@"
else
    composer "$@"
fi

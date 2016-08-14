#!/bin/bash
#
# Script for safe key=value pair storage
#
key_store=~/.gpg-config/

mkdir -p "$key_store"
echo "-- Type value and then press Ctrl-D --"
gpg --encrypt -o "$key_store/$1.gpg"
echo ""
echo "Below value has been stored:"
get-config.sh $1
echo ""

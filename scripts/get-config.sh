#!/bin/bash
#
# Script for safe key=value pair read
#
key_store=~/.gpg-config/

gpg --quiet --for-your-eyes-only --no-tty --decrypt "$key_store/$1.gpg"

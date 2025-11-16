#!/bin/bash
if [[ "$(tty)" == "/dev/tty2" ]]; then
    exec "$HOME/.scripts/steamos"
    exit
fi

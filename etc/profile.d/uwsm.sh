#!/bin/bash
if [[ "$(tty)" == "/dev/tty1" ]]; then
    exec uwsm start default
fi

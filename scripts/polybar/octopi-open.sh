#!/usr/bin/env bash
#=================================================
# name:   octopi-open
# author: Pawel Bogut <https://pbogut.me>
# date:   24/10/2021
#=================================================

printer=$1
url=$(config octopi/url):$(config "octopi/printers/$printer/port")

switch-or-launch.sh -i "^$printer \[octoprint\]" "browser $url"

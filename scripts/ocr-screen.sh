#!/bin/bash
#==================================================
# name:   ocr-screen.sh
# author: Pawel Bogut <http://pbogut.me>
# date:   13/04/2017
#
# Depends on maim, slop and tesseract
# pacman -S slop maim tesseract- tesseract-data-eng
#==================================================
file="/tmp/ocr-$(date +'%s').png"
maim -s $file && \
tesseract $file - \
| xsel -b -i

[[ $1 == "--vim" ]] && vim-anywhere.sh --clipboard

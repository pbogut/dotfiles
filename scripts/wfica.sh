#!/bin/sh
export ICAROOT=/opt/Citrix/ICAClient
${ICAROOT}/wfica -geometry 2000x1500+0+0 -file "$1"

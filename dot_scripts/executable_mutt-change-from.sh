#!/bin/bash
#=================================================
# name:   change_from_and_bcc.sh
# author: Pawel Bogut <https://pbogut.me>
# date:   09/06/2020
#=================================================
# Ussage:
#   macro compose \e2 ":set editor='mutt-change-from.sh email@address.pl'<enter>E:set editor=`echo $EDITOR`<enter>" "change 2"
address=$1
file=$2

sed "s/^From: .*$/From: Paweł Bogut <$address>/g" -i $file
sed "s/^From:$/From: Paweł Bogut <$address>/g" -i $file

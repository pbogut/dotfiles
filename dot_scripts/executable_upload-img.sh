#!/usr/bin/env bash
#=================================================
# name:   upload-img
# author: Pawel Bogut <https://pbogut.me>
# date:   08/03/2022
#=================================================
file=$1
ext=${file##*.}
name=${file%%*/}
sum=$(sha1sum $1 | awk '{print $1}')
new_name="$sum.$ext"


scp "$file" "seagull.pbogut.me:www/storage/img/$new_name"

echo "Result:"
echo "    https://storage.pbogut.me/img/$new_name"
echo "    ![$ext](https://storage.pbogut.me/img/$new_name)"
echo "    ![$new_name](https://storage.pbogut.me/img/$new_name)"

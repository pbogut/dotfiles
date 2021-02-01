#!/bin/bash
#=================================================
# name:   notmuch-archive-big.sh
# author: Pawel Bogut <https://pbogut.me>
# date:   09/12/2020
#=================================================

daysago=365
todate=$(date --date="$daysago days ago" '+%Y-%m-%d')
search="date:..$todate"

notmuch search --output threads $search attachment: | while read thread; do
    size=$(notmuch search --output files $thread | xargs du -c | tail -n1 | awk '{print $1}')
    if [[ $size -gt 5120 ]]; then #only files above 5MB
        #echo $size $thread
        notmuch search --output files $thread | grep -v '\.archive' |
            while read line; do
                origdir=$(dirname $line)
                archdir=$(echo $origdir | sed 's#Maildir/\(.*\)/\(.*\)/\(cur\|new\)#Maildir/\1/\2.archive/\3#')

                filename=$(basename $line)

                #mkdir -p $archdir

                if [[ "$origdir" == "$archdir" ]]; then
                    # already archived
                    continue
                fi

                if [[ ! -f "$origdir/$filename" ]]; then
                    # file do not exist
                    continue
                fi

                echo "$filename:"
                echo "    move $origdir" '->' "$archdir"
                #mv "$origdir/$filename" "$archdir/$filename" >/dev/null 2>&1
            done
    fi
done

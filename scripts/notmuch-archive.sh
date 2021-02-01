#!/bin/bash
#=================================================
# name:   notmuch-archive.sh
# author: Pawel Bogut <https://pbogut.me>
# date:   09/12/2020
#=================================================
#label:simplearchive  after:2006/8/8 before:2011/8/11  - 37 emails total
daysago=1095
todate=$(date --date="$daysago days ago" '+%Y-%m-%d')
search="date:..$todate"
echo notmuch search --output files $search
total=$(notmuch search --output files $search | grep -v '\.archive' | wc -l)
echo "Archive emails before $todate."
echo "> $total files. <"
echo ""
echo "(prass enter to continue)"
read
echo "Start..."

notmuch search --output files $search | grep -v '\.archive' |
    while read line; do
        origdir=$(dirname $line)
        archdir=$(echo $origdir | sed 's#Maildir/\(.*\)/\(.*\)/\(cur\|new\)#Maildir/\1/\2.archive/\3#')



        filename=$(basename $line)

        mkdir -p $archdir

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
        mv "$origdir/$filename" "$archdir/$filename" > /dev/null 2>&1
    done

notmuch new

gmaildaysago=$(expr $daysago + 3)
gmailtodate=$(date --date="$gmaildaysago days ago" '+%Y/%m/%d')
echo ""
echo "To delete files from gmail use this query in web mail: "
echo before:$gmailtodate

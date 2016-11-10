#!/bin/bash
file=~/.abook/addressbook
tmp_file=/tmp/addressbook.tmp
# remove duplicates
abook --convert --infile $file --outformat csv |
        sort | uniq |
        grep -v "newsletter@\|norepl\|no-repl\|@docs.google.com\|@bugs.bugherd.com\|(via Google [^)]*)" |
        grep  "@" |
        abook --convert --informat csv --outformat abook > $tmp_file
mv "$tmp_file" "$file"
# dont want nicks
cat "$file" | sed '/^nick=.*/d' > "$tmp_file"
mv "$tmp_file" "$file"


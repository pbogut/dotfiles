#!/bin/bash
file=~/.abook/addressbook
tmp_file=/tmp/addressbook.tmp
res_file=/tmp/addressbook.res

if [[ ! -e $tmp_file ]]; then
    cp "$file" "$tmp_file"
    # remove duplicates
    abook --convert --infile $tmp_file --outformat csv |
            ruby -ne '
                require "csv"
                row = CSV.parse($_)[0]
                row[1].downcase!
                puts row.to_csv' |
            sort | uniq |
            grep -v "newsletter@\|norepl\|no-repl\|@docs.google.com\|@bugs.bugherd.com\|(via Google [^)]*)" |
            grep  "@" |
            abook --convert --informat csv --outformat abook > $res_file
    mv "$res_file" "$file"
    rm "$tmp_file"
fi

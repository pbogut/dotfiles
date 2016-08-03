#!/bin/bash
file=~/.abook/addressbook
tmp_file=/tmp/addressbook.tmp
# clear file, it will leave only name, email and nick
abook --convert --informat abook --infile "$file" --outformat mutt --outfile "$tmp_file"
mv "$tmp_file" "$file"
abook --convert --informat mutt --infile "$file" --outformat abook --outfile "$tmp_file"
mv "$tmp_file" "$file"
# dont want nicks
cat "$file" | sed '/^nick=.*/d' > "$tmp_file"
mv "$tmp_file" "$file"

# remove duplicates
cat "$file" | sort | uniq -d | while read l; do
    awk '!r && /'"$l"'/ {sub(/'"$l"'/,""); r=1} 1' "$file" > "$tmp_file"
    mv "$tmp_file" "$file"
done

# clear file, it will leave only name, email and nick
abook --convert --informat abook --infile "$file" --outformat mutt --outfile "$tmp_file"
mv "$tmp_file" "$file"
abook --convert --informat mutt --infile "$file" --outformat abook --outfile "$tmp_file"
mv "$tmp_file" "$file"
# dont want nicks
cat "$file" | sed '/^nick=.*/d' > "$tmp_file"
mv "$tmp_file" "$file"


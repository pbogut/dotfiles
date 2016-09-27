#!/bin/bash
if [[ -z $1 ]]; then
    git_dir="`pwd`/.git"
else
    git_dir="$1/.git"
fi

if [[ ! -d $git_dir ]]; then
    echo ""
    echo "$git_dir not found."
    echo -e "\t Usage: $0 [/path/to/git/repo]"
    echo ""
    exit
fi

echo "/tags" >> "$git_dir/info/exclude"
echo "/.padawan" >> "$git_dir/info/exclude"

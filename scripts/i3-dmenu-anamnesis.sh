#!/bin/zsh
# display clipboard text
echo "select docid, replace(c0text, '\n', '¬ ') \
        from clips_content \
        order by docid desc \
        limit 50;" \
        | sqlite3 ~/.local/share/anamnesis/database \
        | rofi -dmenu -l 20 -p 'clipboard:' \
        | sed 's/\([0-9]*\)|.*/\1/g' \
        | read id;

# copy selected to clipboard
if [[ "$id" != "" ]]; then
    echo "select c0text \
        from clips_content \
        where docid = $id \
        order by docid desc;" \
        | sqlite3 ~/.local/share/anamnesis/database \
        | perl -p -e 'chomp if eof' \
        | xclip -in -selection clipboard
fi

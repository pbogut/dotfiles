#!/bin/zsh
echo "select replace(c0text, '\n', '¬n¬') \
        from clips_content \
        order by docid desc \
        limit 50;" | sqlite3 ~/.local/share/anamnesis/database \
            | dmenu -l 20 -p clipboard | sed 's/¬n¬/\n/g' | perl -p -e 'chomp if eof' \
            | xclip -in -selection clipboard


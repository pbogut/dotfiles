#!/bin/zsh
#=================================================
# name:   anamnesis.sh
# author: Pawel Bogut <pbogut@ukpos.com> <http://pbogut.me>
# date:   03/02/2017
#=================================================

extract_id() {
    echo $1 | sed 's/\(^[0-9]*\).*/\1/g'
}

param_or_stdin() {
    if [[ ! $1 == "" ]]; then
        echo $1
    else
        cat -
    fi
}

if [[ $1 == "list" ]]; then
    # display clipboard text
    echo "select docid, replace(substr(c0text, 0, 255), '\n', '¬ ') \
        from clips_content \
        order by docid desc \
        limit 50;" \
        | sqlite3 ~/.local/share/anamnesis/database

elif [[ $1 == "to_clip" ]]; then
    line=$(param_or_stdin $2)
    id=$(extract_id $line)
    if [[ ! $id == "" ]];then
        echo "select c0text \
            from clips_content \
            where docid = $id \
            order by docid desc;" \
            | sqlite3 ~/.local/share/anamnesis/database \
            | perl -p -e 'chomp if eof' \
            | xclip -in -selection clipboard
    fi

elif [[ $1 == "extract_id" ]]; then
    line=$(param_or_stdin $2)
    extract_id $line
fi

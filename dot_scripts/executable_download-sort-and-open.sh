#!/bin/bash
#=================================================
# name:   download-sort-and-open.sh
# author: Pawel Bogut <https://pbogut.me>
# date:   26/12/2020
#=================================================
file="$1"
dir="$(cd "$(dirname "$file")" && pwd)"

open_file() {
    $HOME/.scripts/sway/open "$1"
}

sort_file() {
    sort_file="$1"
    ext=$(echo ${sort_file##*.} | awk '{print tolower($1)}')
    dest_base="$HOME/Downloads"
    dest=$dest_base
    name=$(basename "$sort_file")
    destdir=""

    case $ext in
        zip | rar | 7z | tar | gz | xz | tgz )
            destdir="_archive"
            ;;
        apk )
            destdir="_apk"
            ;;
        jar )
            destdir="_jar"
            ;;
        sql )
            destdir="_sql"
            ;;
        xml | json | yaml | yml )
            destdir="_markup"
            ;;
        pdf )
            destdir="_pdf"
            ;;
        sh | zsh | fsh | vbs )
            destdir="_script"
            ;;
        png | jpg | jpeg | gif | svg )
            destdir="_image"
            ;;
        mpg | mpeg | avi | mp4 )
            destdir="_video"
            ;;
        mp3 | wav | flac )
            destdir="_music"
            ;;
        stl | gcode | scad | skp )
            destdir="_model_3d"
            ;;
        xlsx | xls | ods | csv )
            destdir="_spreadsheet"
            ;;
        docx | doc | odt | txt )
            destdir="_document"
            ;;
        torrent )
            destdir="_torrent"
            ;;
        * )
            destdir=""
            ;;
    esac

    if [[ $destdir != "" ]]; then
        dest_file="$dest_base/$destdir/$name"
        mkdir -p $(dirname $dest_file)
        [[ -f $sort_file ]] && mv "$sort_file" "$dest_file"
        open_file "$dest_file"
    else
        echo $sort_file not going to be moved
    fi
}

if [[ $dir == "$HOME/Downloads" ]] || [[ $dir == "/storage/downloads" ]]; then
    sort_file "$file"
else
    open_file "$file"
fi

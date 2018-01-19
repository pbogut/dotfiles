#!/bin/bash
#=================================================
# name:   quickbrowser.sh
# author: Pawel Bogut <http://pbogut.me>
# date:   18/01/2018
#=================================================

(
  echo "Quickmarks"
  cat $HOME/.config/qutebrowser/quickmarks |
    sed -E 's,(.*) (http.?://[^ ]*),\2}\1,'
  echo "Bookmarks"
  cat $HOME/.config/qutebrowser/bookmarks/urls |
    sed -E 's,(http.?://[^ ]*) (.*),\1}\2,'
  echo "History"

  echo "select url, title \
  from history \
  order by atime desc
  limit 250;" |
    sqlite3 ~/.local/share/qutebrowser/history.sqlite |
    sed -E 's,(http.?://[^|]*)\|(.*),\1}\2,'
) | (while read line; do
  c=$(expr 1 + 0$c)
  echo $c}$line
done) |
  tee $TMPDIR/qutebrowser_temp_history.txt |
  sed -E 's,(.*)}(.{120}).*}(.*),\1}\2}\3,' |
  column -s '}' -t |
  rofi -dmenu -prompt "Web" |
  sed -E 's,(\d*) .*,\1,'

echo $selected
test -n "$selected" &&
  browser $(
    grep "^$selected}" $TMPDIR/qutebrowser_temp_history.txt |
      sed -E 's,.*}(.*)}.*,\1,'
  )

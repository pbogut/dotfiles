#!/bin/sh
#
# When *.php files in the current directory are modified, this script runs
# their corresponding *Test.php files and prints any errors or test fails.
#
# Usage: inotifytest-php.sh [src-dir] [dest-dir]
#
#        if src and dest dirs provideded, script will replace these in path
#        when looking for corresponding test file
#
# Original script written in 2013 by Suraj N. Kurapati <https://github.com/sunaku>
# for ruby files https://github.com/sunaku/home/blob/master/bin/inotifytest-ruby
#
# Modified in 2016 by Pawel Bogut <https://github.com/pbogut>

srcdir="${1:-.}"
mainfile="${2:-Main.elm}"
options=${@:3}

echo -e "Watching dir: \t$srcdir\nCommand to run:\telm-make $mainfile $options"

inotifywait -rqme close_write --format '%w%f' $srcdir | while read -r file; do {

  # only process *.php files - ignore all other files
  test "${file%.elm}" = "$file" && continue

  # keep track of which test file is being run & when
  clear

  # run test file and print any errors or test fails
  elm-make $srcdir/$mainfile $options
  make_exit_status=$?
  test $make_exit_status -eq 0 && notify-send -i /usr/share/icons/gnome/48x48/emblems/emblem-default.png "Compiled successfully"
  test $make_exit_status -eq 0 || notify-send -i /usr/share/icons/gnome/48x48/emblems/emblem-important.png "Compile failed"

} </dev/null
done

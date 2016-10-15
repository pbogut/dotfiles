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

srcdir="$1"
testdir="$2"

inotifywait -rqme close_write --format '%w%f' . | while read -r file; do {

  # only process *.php files - ignore all other files
  test "${file%.php}" = "$file" && continue

  # map the *.php file to its corresponding *Test.php
  # file, unless it already _is_ that *Test.php file!
  test "${file%Test.php}" = "$file" &&
                            file=${file%.php} &&
                            file=$(ls "${file/$srcdir/$testdir}"*"Test.php" 2>/dev/null)
  if [ $? != 0 ]; then
    white='\033[0;37m'        # White
    on_red='\033[41m'         # Red
    color_off='\033[0m'
    echo -e "\n${white}${on_red}Test file not found, fancy to write one?${color_off}\n"
  fi
  # make sure *Test.php file exists before running it
  test -f "$file" || continue

  # keep track of which test file is being run & when
  clear
  echo "\033[36m$file @ $(date)\033[0m"

  # run test file and print any errors or test fails
  php vendor/bin/phpunit "$file"
  test_exit_status=$?
  # test $test_exit_status -eq 0 && notify-send -i /usr/share/icons/gnome/48x48/emblems/emblem-default.png "Tests passed"
  # test $test_exit_status -eq 0 || notify-send -i /usr/share/icons/gnome/48x48/emblems/emblem-important.png "Tests failed"

} </dev/null
done


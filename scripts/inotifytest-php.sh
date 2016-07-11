#!/bin/sh
#
# When *.php files in the current directory are modified, this script runs
# their corresponding *Test.php files and prints any errors or test fails.
#
# Original script written in 2013 by Suraj N. Kurapati <https://github.com/sunaku>
# for ruby files https://github.com/sunaku/home/blob/master/bin/inotifytest-ruby
#
# Modified in 2016 by Pawel Bogut <https://github.com/pbogut>

inotifywait -rqme close_write --format '%w%f' . | while read -r file; do {

  # only process *.php files - ignore all other files
  test "${file%.php}" = "$file" && continue

  # map the *.php file to its corresponding *Test.php
  # file, unless it already _is_ that *Test.php file!
  test "${file%Test.php}" = "$file" && file=$(ls "${file%.php}"*"Test.php")

  # make sure *Test.php file exists before running it
  test -f "$file" || continue

  # keep track of which test file is being run & when
  clear
  echo "\033[36m$file @ $(date)\033[0m"

  # run test file and print any errors or test fails
  php vendor/bin/phpunit "$file"

} </dev/null
done

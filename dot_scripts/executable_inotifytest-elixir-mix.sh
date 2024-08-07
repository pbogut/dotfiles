#!/bin/sh -u
#
# Setup: apt-get install inotify-tools
#
# Usage: inotifytest-elixir-mix [ARGUMENTS_FOR_MIX_TEST...]
#
# When *.exs files in or beneath lib/ or test/ are modified, this script runs
# their corresponding test/*test.exs files and prints any errors or failures.
# If any other test/*.exs file is modified, then all available tests are run.
#
# Written in 2014 by Suraj N. Kurapati <https://github.com/sunaku>

notification_id=0

notify() {
  if [[ $notification_id -eq 0 ]]; then
    notification_id=$(dunstify -p -I "$1" "$2" "$(date +'%H:%M:%S.%N')")
  else
    dunstify -r $notification_id -I "$1" "$2" "$(date +'%H:%M:%S.%N')"
  fi
}
map_file_to_test() { file=$1
  case "$file" in
    (lib/*.ex|lib/*.exs) test=test${file#lib}
                         test=${test%.*}_test.exs ;; # perform the mapping
    (test/*test.exs)     test=$file               ;; # file is test itself
    (test/*.exs)         test=                    ;; # file is test helper
    (*)                  return 1                 ;; # file not recognized
  esac
  test -n "$test" -a -f "$test" && echo "$test" || : # print only if exist
}

test_exit_status=0

inotifywait -rqme close_write --format '%w%f' lib/ test/ |
while read -r changed_file; do {

  changed_file_test=$(map_file_to_test "$changed_file") || continue

  test $test_exit_status -eq 0 && clear
  printf '\033[33m%s -> \033[36m%s\033[0m\n' \
    "$(date -r "$changed_file" '+%X')" "$changed_file"

  compiled_files=$(
    MIX_ENV=test mix compile --verbose | tee /dev/tty |
    awk '/^Compiled .+\.ex$/ { $1=""; print }
         /^==/ { error=1 } END { exit error }'
  ) || continue

  compiled_file_tests=$(
    for compiled_file in $compiled_files; do
      map_file_to_test "$compiled_file"
    done
  )

  mix test "$@" $changed_file_test $compiled_file_tests
  test_exit_status=$?
  test $test_exit_status -eq 0 && notify /usr/share/icons/gnome/48x48/emblems/emblem-default.png "Tests passed"
  test $test_exit_status -eq 0 || notify /usr/share/icons/gnome/48x48/emblems/emblem-important.png "Tests failed"

} </dev/null
done

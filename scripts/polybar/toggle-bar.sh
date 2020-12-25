#!/bin/bash
#=================================================
# name:   toggle-bar.sh
# author: Pawel Bogut <https://pbogut.me>
# date:   24/12/2020
#=================================================
bar=$1
pidfile=$TMPDIR/polybar_$bar.pid
pid=$(cat $pidfile)

close_deferrer() {
  sleep 10s;
  if [[ $(cat $pidfile) == $pid ]]; then
    close_bar
  fi
}

open_bar() {
  polybar $bar &
  pid=$!
  echo $pid > $pidfile
  close_deferrer &
}

close_bar() {
  echo "" > $pidfile
  kill $pid
}

if [[ $pid == "" ]]; then
  open_bar
else
  close_bar
fi


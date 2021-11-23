#!/bin/bash


sleep=0
while test $# -gt 0; do
  case "$1" in
    --sleep)
      sleep=$2
      shift
      shift
      ;;
    *)
      shift
      ;;

  esac
done



try_to_run() {
  type $1 > /dev/null 2>&1
  if [[ $? == 0 ]]; then
    $@
    return 0
  fi

  return 1
}

lock_screen() {
  try_to_run i3lock-fancy-dualmonitor ||
  try_to_run i3lock-fancy ||
  try_to_run gllock ||
  try_to_run i3lock --nofork
}

fix_postsuspend() {
  # fix laptop touchpad issues
  sudo -n modprobe -r hid_multitouch
  sudo -n modprobe hid_multitouch
}

# lay=`setxkbmap -print | grep 'pc+' | sed 's/.*pc+\([^+]*\)+.*/\1/' | sed 's/[()]/ /g' | sed 's/ / -variant /'`
# setxkbmap pl
dunstctl set-paused true
(lock_screen &&
dunstctl set-paused false &&
fix_postsuspend()
) &
sleep "${sleep}s";

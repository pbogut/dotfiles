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
  if type "$1" > /dev/null 2>&1; then
    "$@"
    return $?
  fi

  return 1
}

lock_screen() {
  try_to_run swaylock -i ~/.config/sway/locktile.png -t ||
  try_to_run i3lock --nofork --image /usr/share/i3-lock-session/locktile.png -t ||
  try_to_run i3lock-fancy-dualmonitor ||
  try_to_run i3lock-fancy ||
  try_to_run gllock ||
  try_to_run i3lock --nofork
}

# lay=`setxkbmap -print | grep 'pc+' | sed 's/.*pc+\([^+]*\)+.*/\1/' | sed 's/[()]/ /g' | sed 's/ / -variant /'`
# setxkbmap pl
dunstctl set-paused true
(
lock_screen &&
dunstctl set-paused false &&
picom -b > /dev/null 2>&1
) &
sleep "${sleep}s";

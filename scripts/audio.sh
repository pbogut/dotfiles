#!/usr/bin/env bash
#=================================================
# name:   audio
# author: author <author_contact>
# date:   19/03/2023
#=================================================
usage() {
  echo "Ussage: ${0##*/} [OPTIONS]"
  echo ""
  echo "Options:"
  echo "  -h, --help           display this help and exit"
  echo "  -n, --next           set next device as default"
  echo "  --in                 operate on input devices"
  echo "  --out                operate on output devices"
  echo "  --without=<device>   filter out <device> pattern"
}

object="sink"
without=""

__audio_get_name() {
    id=$1
    pulsemixer --list-$object | grep "\-$id, Name: " | sed 's/.*Name: \(.*\), Mute:.*/\1/'
}

__audio_get_id() {
  if [[ $object == "sink" ]]; then
    # shellcheck disable=2001
    (grep -v 'sink-input-\|Monitor of' |
      sed "s/.*ID: $object\-\([0-9]\+\),.*/\1/g") </dev/stdin
  elif [[ $object == "source" ]]; then
    # shellcheck disable=2001
    (grep -v 'source-output-\|Monitor of' |
      sed "s/.*ID: $object\-\([0-9]\+\),.*/\1/g") </dev/stdin
  fi

}

__audio_current() {
  id=$(pulsemixer --list-$object | grep ', Default$' | __audio_get_id)
  echo "$id"
}

__audio_list() {
  list=""
  if [[ -n "$without" ]]; then
    list=$(pulsemixer --list-$object | grep -v "$without" | __audio_get_id)
  else
    list=$(pulsemixer --list-$object | __audio_get_id)
  fi

  echo "$list"
}

__audio_next() {
  current=$(__audio_current)
  next=$(__audio_list | sed -n "/$current/,"'$p' | head -n2 | tail -n1)

  if [[ -z "$next" ]] || [[ "$current" == "$next" ]]; then
    next=$(__audio_list | head -n1)
  fi

  echo "$next"
}

while test $# -gt 0; do
  case "$1" in
  --without | --without=* | -o)
    if [[ $1 =~ --[a-z]+= ]]; then
      _val="${1//--without=/}"
      shift
    else
      _val="$2"
      shift
      shift
    fi
    without="$_val"
    ;;
  --in)
    object="source"
    shift
    ;;
  --out)
    object="sink"
    shift
    ;;
  --next | -n)
    action="next"
    shift
    ;;
  --help | -h)
    usage
    exit 0
    ;;
  *)
    usage
    exit 1
    ;;
  esac
done

echo "List:"
__audio_list
echo "Current:"
__audio_current
echo "Next:"
__audio_next

if [[ $action == "next" ]]; then
  next=$(__audio_next)
  notify-send "Audio" "Switching audio device:\n$(__audio_get_name "$next")" -i audio-volume-high
  pactl set-default-$object "$(__audio_next)"
fi

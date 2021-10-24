#!/bin/bash
#=================================================
# name:   switch-or-launch.sh
# author: Pawel Bogut <http://pbogut.me>
# date:   15/07/2017
#=================================================
last_id_file="/tmp/$USER/_switch-or-launch.last_id"
workspc_file="/tmp/$USER/_switch-or-launch.workspc"

usage() {
  echo "Ussage: ${0##*/} [OPTIONS] <pattern> <command>"
  echo ""
  echo "Arguments:"
  echo "  <pattern>            window class/title pattern"
  echo "  <command>            command to run pattern not found"
  echo ""
  echo "Options:"
  echo "  -s, --scratchpad     floating/scratchpad window"
  echo "  -h, --help           display this help and exit"
}

get_windows() {
  wmctrl -lx | awk '{id=$1; $1=$2=$3=$4=""; print id $0}' | while read -r id title; do
    echo "$id" $(print "$title")
  done
}

print() {
  if [[ $ignore_case -eq 1 ]]; then
    echo "$@" | awk '{print tolower($0)}'
  else
    echo "$@"
  fi
}

get_window_id() {
  wmctrl -lx | awk '{id=$1; cls=$3; $1=$2=$3=$4=""; print id "\t" cls $0}' |
    while read -r id cls title; do
      if [[ $(print "$title" | grep -E "$1") ]]; then
        echo $(( id ))
        return 0
      fi
      if [[ $(print "$cls" | grep -E "$1") ]]; then
        echo $(( id ))
        return 0
      fi
    done
}

scratchpad=0
pattern=""
command=""
ignore_case=0

while test $# -gt 0; do
  case "$1" in
    --ignore-case|-i)
      ignore_case=1
      shift
      ;;
    --scratchpad|-s)
      scratchpad=1
      shift
      ;;
    --help|-h)
      usage
      exit 0
      ;;
    *) #positional
      if [[ -z $pattern ]]; then
        pattern=$1
      elif [[ -z $command ]]; then
        command=$1
      else
        usage
        exit 1
      fi
      shift
      ;;
  esac
done

if [[ -z $pattern ]] || [[ -z $command ]]; then
  usage
  exit 1
fi

mkdir -p $(dirname $last_id_file)
touch $last_id_file
touch $workspc_file

last_id=$(cat $last_id_file)
id=$(xdotool getwindowfocus)

if [[ $scratchpad -eq 0 ]]; then
  echo "$id" > "$last_id_file"
fi

win=$(get_window_id "$pattern")

# app currently focused
if [[ -n $id && "$win" == "$id" ]]; then
  if [[ $scratchpad -eq 1 ]]; then
    i3-msg move scratchpad
  else
    cat $workspc_file | while read workspc_id; do
      i3-msg -t command  workspace $workspc_id
    done
    sleep 0.15s;
    wmctrl -ia "$last_id"
  fi
else
  if [[ $scratchpad -eq 1 ]]; then
    win=$(get_window_id "$pattern")
    if [[ -n $win ]]; then # command already ran
      i3-msg '[title="'"$pattern"'"]' scratchpad show
    else # command needs to be started
      $command &
    fi
  else
    i3-msg -t get_workspaces | jq '.[] | select(.visible==true).name' | cut -d"\"" -f2 "$workspc_file"

    win=$(get_window_id "$pattern")
    if [[ -n $win ]]; then # command already ran
      wmctrl -ia "$win" # focus app window
    else # command needs to be started
      $command &
      # wait for app to be open
      for _ in {1..30}; do
        sleep 0.1s
        win=$(get_window_id "$pattern")
        if [[ -n $win ]]; then
          break
        fi
      done
      # focus app window
      wmctrl -ia "$win"
    fi
  fi
fi

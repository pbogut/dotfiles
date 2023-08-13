#!/usr/bin/env bash
#=================================================
# name:   video-convirsion
# author: Pawel Bogut <https://pbogut.me>
# date:   24/02/2022
#=================================================


input_file=""
output_file=""
crf=""
codec="hevc_nvenc"

usage() {
  echo "Ussage: ${0##*/} [OPTIONS] <input> <output>"
  echo ""
  echo "Options:"
  echo "  -h, --help     display this help and exit"
  echo "  -c, --crf      compression crf level"
  echo "  -h264          use h264 codec (w/crf 23)"
  echo "  -hevc          use hevc codec (default) (w/crf 25)"
}

while test $# -gt 0; do
  case "$1" in
    --h264)
      codec="h264_nvenc"
      if [[ -z $crf ]]; then
        crf="23"
      fi
      shift
      ;;
    --hevc)
      codec="hevc_nvenc"
      if [[ -z $crf ]]; then
        crf="25"
      fi
      shift
      ;;
    --crf|--crf=*|-c)
      if [[ $1 =~ --[a-z]+= ]]; then
        _val="${1//--crf=/}"
        shift
      else
        _val="$2"
        shift; shift
      fi
      crf="$_val"
      ;;
    --help|-h)
      usage
      exit 0
      ;;
    *)
      if [[ -z $input_file ]]; then
        input_file="$1"
      elif [[ -z $output_file ]]; then
        output_file="$1"
      else
        usage
        exit 1
      fi
      shift
      ;;
  esac
done

if [[ -z $input_file || -z $output_file ]]; then
  usage
  exit 1
fi

if [[ -z $crf ]]; then
  crf="25"
fi

echo "Running conversion command:"
echo "> " ffmpeg -i "$input_file" -c:v hevc_nvenc -c:a copy -x265-params crf="$crf" "$output_file"

# ffmpeg -i "$input_file" -c:v hevc_nvenc -c:a copy -x265-params crf="$crf" "$output_file"
ffmpeg -i "$input_file" -c:v "$codec" -c:a copy -x265-params crf="$crf" "$output_file"



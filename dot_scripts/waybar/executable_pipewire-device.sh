#!/usr/bin/env bash
#=================================================
# name:   executable_pipewire-device
# author: Pawel Bogut <pbogut@pbogut.me>
# date:   29/07/2026
#=================================================
set -euo pipefail

sink_blacklist=(
    # Add exact node names from `wpctl status --name`, one per line.
    # "alsa_output.pci-0000_00_1f.3.hdmi-stereo"
    "easyeffects_sink"
    "alsa_output.pci-0000_0d_00.4.iec958-stereo"
    "alsa_output.usb-Fifine_Microphones_fifine_Microphone_REV1.0-00.analog-stereo"
)

usage() {
    echo "Usage: ${0##*/} [toggle]"
}

is_blacklisted() {
    local sink_name=$1
    local blocked

    for blocked in "${sink_blacklist[@]}"; do
        if [[ "$sink_name" == "$blocked" ]]; then
            return 0
        fi
    done

    return 1
}

sink_info() {
    LC_ALL=C wpctl inspect "$1" | awk -F '"' '
        NR == 1 {
            id = $0
            sub(/^id /, "", id)
            sub(/,.*/, "", id)
        }
        /node.description = "/ { description = $2 }
        /node.nick = "/ { nick = $2 }
        /node.name = "/ { name = $2 }
        END {
            if (description != "") {
                name = description
            } else if (nick != "") {
                name = nick
            }

            if (id != "" && name != "") {
                print id "\t" name
            }
        }
    '
}

sink_entries() {
    LC_ALL=C wpctl status --name | awk '
        /Sinks:$/ && !found_sinks {
            found_sinks = 1
            in_sinks = 1
            next
        }
        in_sinks && /Sources:$/ { exit }
        in_sinks && match($0, /[0-9]+\./) {
            id = substr($0, RSTART, RLENGTH - 1)
            name = substr($0, RSTART + RLENGTH)
            sub(/^[[:space:]]*/, "", name)
            sub(/[[:space:]]+\[vol:.*/, "", name)
            print id "\t" name
        }
    '
}

action="${1:-show}"
case "$action" in
    show|toggle)
        ;;
    --help|-h)
        usage
        exit 0
        ;;
    *)
        usage >&2
        exit 1
        ;;
esac

if (( $# > 1 )); then
    usage >&2
    exit 1
fi

current=$(sink_info '@DEFAULT_AUDIO_SINK@')
if [[ -z "$current" ]]; then
    echo "No default PipeWire sink found" >&2
    exit 1
fi

current_id=${current%%$'\t'*}
current_name=${current#*$'\t'}

if [[ "$action" == "show" ]]; then
    echo "$current_name"
    exit 0
fi

mapfile -t sinks < <(sink_entries)
if (( ${#sinks[@]} == 0 )); then
    echo "No PipeWire sinks found" >&2
    exit 1
fi

current_index=-1
for index in "${!sinks[@]}"; do
    sink_id=${sinks[$index]%%$'\t'*}
    if [[ "$sink_id" == "$current_id" ]]; then
        current_index=$index
        break
    fi
done

next_id=""
sink_count=${#sinks[@]}
for (( offset = 1; offset <= sink_count; offset++ )); do
    index=$(( (current_index + offset) % sink_count ))
    sink_id=${sinks[$index]%%$'\t'*}
    sink_name=${sinks[$index]#*$'\t'}

    if is_blacklisted "$sink_name"; then
        continue
    fi

    next_id=$sink_id
    break
done

if [[ -z "$next_id" ]]; then
    echo "No non-blacklisted PipeWire sinks found" >&2
    exit 1
fi

wpctl set-default "$next_id"
next=$(sink_info "$next_id")
echo "${next#*$'\t'}"

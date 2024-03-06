#!/bin/bash
# Default acpi script that takes an entry for all actions
#
# Add system file: /etc/acpi/events/anything_custom    +x
#
# # file content start #
# event=.*
# action=/home/pbogut/.scripts/acpi_handler.sh %e
# # file content end   #
#
dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
run="sudo -u pbogut "
logger "EVENT: 1:$1< 2:$2< 3:$3< 4:$4< 5:$5< 6:$6<"
case "$1" in
    button/power)
        case "$2" in
            PBTN|PWRF)
                logger 'PowerButton pressed'
                ;;
            *)
                logger "ACPI action undefined: $2"
                ;;
        esac
        ;;
    button/sleep)
        case "$2" in
            SLPB|SBTN)
                logger 'SleepButton pressed'
                ;;
            *)
                logger "ACPI action undefined: $2"
                ;;
        esac
        ;;
    ac_adapter)
        case "$4" in
            00000000)
                logger 'AC unpluged'
                $run $dir/battery-save on
                ;;
            00000001)
                logger 'AC pluged'
                $run $dir/battery-save off
                ;;
        esac
        ;;
    battery)
        case "$4" in
            00000000)
                logger 'Battery online'
                ;;
            00000001)
                logger 'Battery offline'
                ;;
        esac
        ;;
    button/lid)
        case "$3" in
            close)
                logger 'LID closed'
                ;;
            open)
                logger 'LID opened'
                ;;
            *)
                logger "ACPI action undefined: $3"
                ;;
    esac
    ;;
    *)
        logger "ACPI group/action undefined: $1 / $2"
        ;;
esac

# vim:set ts=4 sw=4 ft=sh et:

#!/bin/bash
#=================================================
# name:   win-mon.sh
# author: Pawel Bogut <https://pbogut.me>
# date:   06/08/2018
#=================================================

vm_status() {
    IS_RUNNING=$(sudo virsh list --all | grep -e 'Win10.*running')
}

check() {
    if [[ -n $IS_RUNNING ]]; then
        source ~/.screenlayout/1-monitor.sh
    else
        source ~/.screenlayout/2-monitors.sh
        # echo 1 | sudo tee "/sys/bus/pci/devices/0000:11:00.3/remove"
        # echo 1 | sudo tee "/sys/bus/pci/rescan"
    fi
}

while :; do
    echo Checking status
    vm_status
    check
    sleep 3s
    echo Waiting for event...
    sudo virsh event --event lifecycle
done

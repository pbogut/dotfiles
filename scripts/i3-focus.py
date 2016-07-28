#!/usr/bin/python

import i3
import subprocess
import sys

if __name__ == '__main__':
    direction = str(sys.argv[1])
    xdo_cmd_dict = {
        'left': 'ctrl+h',
        'down': 'ctrl+j',
        'up': 'ctrl+k',
        'right': 'ctrl+l'
    }
    current = i3.filter(nodes=[], focused=True)[0]
    if 'tmux' in current['name']:
        # wid = current['window']
        # xdotool_call = ["xdotool", "windowactivate", str(wid)]
        # xdotool_call = ["xdotool", "key", xdo_cmd_dict[direction]]
        # xdotool_call = ["xdotool", "key", "--window", str(wid), xdo_cmd_dict[direction]]
        # subprocess.call(xdotool_call)
        #todo get session id and use it in tmux command
        subprocess.call("~/.scripts/tmux-focus.sh " + direction, shell=True)
    else:
        i3.focus(direction)

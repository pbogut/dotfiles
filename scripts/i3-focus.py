#!/usr/bin/python
import re
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
    tmux_dir = {
        'left': 'c-h',
        'down': 'c-j',
        'up': 'c-k',
        'right': 'c-l'
    }
    current = i3.filter(nodes=[], focused=True)[0]
    name = current['name']
    if 'tmux' in name:
        # wid = current['window']
        # xdotool_call = ["xdotool", "windowactivate", str(wid)]
        # xdotool_call = ["xdotool", "key", xdo_cmd_dict[direction]]
        # xdotool_call = ["xdotool", "key", "--window", str(wid), xdo_cmd_dict[direction]]
        # subprocess.call(xdotool_call)
        #todo get session id and use it in tmux command
        # subprocess.call("~/.scripts/tmux-focus.sh " + direction, shell=True)
        session_id = re.search(r"tmux \$(\d+):", name).group(1)
        subprocess.call("tmux send-keys -t " + session_id + " " + tmux_dir[direction], shell=True)
        # subprocess.call("tmux send-keys -t " + tmux_dir[direction], shell=True)
        # subprocess.call("tmux select-pane -L " + tmux_dir[direction], shell=True)
    else:
        i3.focus(direction)

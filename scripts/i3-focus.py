#!/usr/bin/python
import re
import i3
import subprocess
import sys

def is_tmux_edge(session_id, direction):
    list_command = "tmux list-panes -t \\" + session_id + " "
    grep = " | grep '1$' |sed 's/1$//'"
    commands = {
        'left': list_command + "-F '#{pane_left}#{pane_active}'" + grep,
        'down': list_command + "-F '#{pane_bottom}#{pane_active}'" + grep,
        'up': list_command + "-F '#{pane_top}#{pane_active}'" + grep,
        'right': list_command + "-F '#{pane_right}#{pane_active}'" + grep,
        'width': list_command + "-F '#{window_width}#{pane_active}'" + grep,
        'height': list_command + "-F '#{window_height}#{pane_active}'" + grep
    }

    proc = subprocess.Popen(commands[direction], stdout=subprocess.PIPE, shell=True)
    offset = int(proc.stdout.read())

    if direction == "right":
        proc = subprocess.Popen(commands["width"], stdout=subprocess.PIPE, shell=True)
        window_width = int(proc.stdout.read())
    if direction == "down":
        proc = subprocess.Popen(commands["height"], stdout=subprocess.PIPE, shell=True)
        window_height = int(proc.stdout.read())
        print (window_height)

    if direction == "left" and offset == 0: return True
    if direction == "right" and window_width - offset == 1: return True
    if direction == "up" and offset == 0: return True
    if direction == "down" and window_height - offset == 1: return True

    return False


if __name__ == '__main__':
    direction = str(sys.argv[1])
    pane_dir = {
        'left': '-L',
        'down': '-D',
        'up': '-U',
        'right': '-R'
    }

    current = i3.filter(nodes=[], focused=True)[0]
    name = current['name']

    if 'tmux' in name:
        session_id = "$" + re.search(r"tmux \$(\d+):", name).group(1)

        if is_tmux_edge(session_id, direction):
            subprocess.Popen("i3-msg focus " + direction, shell=True)
        else:
            subprocess.Popen("tmux select-pane -t \\" + session_id + " " + pane_dir[direction], shell=True)
    else:
        i3.focus(direction)

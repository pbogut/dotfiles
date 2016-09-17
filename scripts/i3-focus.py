#!/usr/bin/python
import re
import i3
import subprocess
import sys
import argparse

def validate_direction(parser, val):
    if val not in ['left', 'right', 'up', 'down']:
        parser.error('{} is not a valid direction.'.format(val))
    return val

parser = argparse.ArgumentParser(description='Toggle between visible workspaces.')
parser.add_argument('direction',
                    help='Focus direction, can be left, right, up or down',
                    type=lambda val: validate_direction(parser, val))
parser.add_argument('--skip-vim', dest='skip_vim', action='store_const',
                    help='swich to the provious workspace (by default it goes to next)',
                    const=True, default=False)


args = parser.parse_args()

def is_vim_in_tmux(session_id):
    if args.skip_vim: return False

    grep = " | grep '1$' |sed 's/1$//'"
    command = "tmux list-pane -F '#{pane_current_command}#{pane_active}'" + grep
    proc = subprocess.Popen(command, stdout=subprocess.PIPE, shell=True)
    current_command = proc.stdout.read()

    return current_command in ['vim',
                               'nvim',
                               'vimdiff',
                               'dirdiff',
                               b'vimdiff\n',
                               b'dirdiff\n',
                               b'vim\n',
                               b'nvim\n']

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
    direction = args.direction
    pane_dir = {
        'left': '-L',
        'down': '-D',
        'up': '-U',
        'right': '-R'
    }
    vim_dir = {
        'left': 'm-a',
        'down': 'm-r',
        'up': 'm-w',
        'right': 'm-t'
    }

    current = i3.filter(nodes=[], focused=True)[0]
    name = current['name']

    if  bool(re.match(r'.* tmux \$\d+:\d+:\d+$', name)):
        session_id = "$" + re.search(r"tmux \$(\d+):", name).group(1)

        if is_vim_in_tmux(session_id):
            # send esc to make sure your in normal mode (its buggy sometimes ;S)
            subprocess.Popen("tmux send-keys -t \\" + session_id + " Escape", shell=True)
            # then send I3Focus trigger combination
            subprocess.Popen("tmux send-keys -t \\" + session_id + " " + vim_dir[direction], shell=True)
        else:

            if is_tmux_edge(session_id, direction):
                i3.focus(direction)
            else:
                subprocess.Popen("tmux select-pane -t \\" + session_id + " " + pane_dir[direction], shell=True)
    else:
        i3.focus(direction)

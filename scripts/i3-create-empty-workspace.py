#!/usr/bin/python2.7
# Swith between workspaces
# Usage:
#   Go to new empty workspace:
#     i3-create-empty-workspace.py
#   Go to new workspace with current container:
#     i3-create-empty-workspace.py move
#   Send current container to new workspace, but stay in the current one:
#     i3-create-empty-workspace.py send

import i3
import sys


move = None
send = None

if(len(sys.argv) >= 2):
    move = str(sys.argv[1]) == "move"
    send = str(sys.argv[1]) == "send"

workspaces = []
for workspace in i3.get_workspaces():
    workspaces.append(workspace['name'])

for i in range(1, 100): # I guess 100 workspaces its already too much
    if str(i) not in workspaces:
        if send or move:
            i3.command('move', 'container to workspace {i}'.format(i=i))
        if not send:
            i3.workspace(str(i))
        break

#!/usr/bin/env python
# Swith between workspaces
# Usage:
#   Go to new empty workspace:
#     i3-create-empty-workspace.py
#   Go to new workspace with current container:
#     i3-create-empty-workspace.py move
#   Send current container to new workspace, but stay in the current one:
#     i3-create-empty-workspace.py send

import i3
import argparse

parser = argparse.ArgumentParser(description='Creates new workspace')
parser.add_argument('--move', dest='move', action='store_const',
                    help='move focused window to new workspace',  const=True,
                    default=False)
parser.add_argument('--send', dest='send', action='store_const',
                    help='send focus window to new workspace while '
                    'staying on current workspace', const=True, default=False)

args = parser.parse_args()

workspaces = []
for workspace in i3.get_workspaces():
    workspaces.append(workspace['name'])

for i in range(1, 100):  # I guess 100 workspaces its already too much
    if str(i) not in workspaces:
        if args.send or args.move:
            i3.command('move', 'container to workspace {i}'.format(i=i))
        if not args.send:
            i3.workspace(str(i))
        break

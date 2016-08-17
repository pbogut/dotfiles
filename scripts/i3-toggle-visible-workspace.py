#!/usr/bin/python2.7
# Swith between workspaces
# Usage:
#     i3-toggle-visible-workspace.py next
#     i3-toggle-visible-workspace.py prev

import i3
import sys

if(len(sys.argv) >= 2):
    prev = str(sys.argv[1]) == "prev"
else:
    prev = False

workspaces = []
for workspace in i3.get_workspaces():
    if workspace['visible']:
        workspaces.append(workspace)

workspaces.extend(workspaces)

if prev:
    workspaces.reverse()

switch_to = False
for workspace in workspaces:
    if switch_to:
        i3.workspace(workspace['name'])
        break
    if workspace['focused']:
        switch_to = True

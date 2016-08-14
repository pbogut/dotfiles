#!/usr/bin/python2.7
# Swith between workspaces
# Usage:
#     i3-switch-workspace.py next
#     i3-switch-workspace.py prev

import i3
import sys


def get_current_output():
    for workspace in i3.get_workspaces():
        if workspace['focused']:
            return workspace['output']
    return None

if(len(sys.argv) >= 2):
    prev = str(sys.argv[1]) == "prev"
else:
    prev = False

if(len(sys.argv) >= 3):
    same_output = str(sys.argv[2]) == "same_output"
else:
    same_output = False

current_output = get_current_output()

workspaces = i3.get_workspaces()
workspaces.extend(workspaces)

if prev:
    workspaces.reverse()

switch_to = False
for workspace in workspaces:
    if (same_output and workspace['output'] != current_output):
        continue
    if switch_to:
        i3.workspace(workspace['name'])
        break
    if workspace['focused']:
        switch_to = True

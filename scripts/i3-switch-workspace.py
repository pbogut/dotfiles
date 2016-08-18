#!/usr/bin/python2.7

import i3
import sys
import argparse

parser = argparse.ArgumentParser(description='Switch between workspaces')
parser.add_argument('--prev', dest='direction', action='store_const',
                    help='swich to the provious workspace (by default it goes to next)',
                    const="prev", default="next")
parser.add_argument('--next', dest='direction', action='store_const',
                    help='swich to the next workspace (default)',  const="next",
                    default="next")
parser.add_argument('--same-output', dest='same_output', action='store_const',
                    help='switch only between workspaces on the current output',
                    const=True, default=False)

args = parser.parse_args()

def get_current_output():
    for workspace in i3.get_workspaces():
        if workspace['focused']:
            return workspace['output']
    return None

current_output = get_current_output()

workspaces = i3.get_workspaces()
workspaces.extend(workspaces)

if args.direction == "prev":
    workspaces.reverse()

switch_to = False
for workspace in workspaces:
    if (args.same_output and workspace['output'] != current_output):
        continue
    if switch_to:
        i3.workspace(workspace['name'])
        break
    if workspace['focused']:
        switch_to = True

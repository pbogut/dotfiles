#!/usr/bin/python2.7
import i3
import sys
import argparse

parser = argparse.ArgumentParser(description='Toggle between visible workspaces.')
parser.add_argument('--prev', dest='direction', action='store_const',
                    help='swich to the provious workspace (by default it goes to next)',  const="prev", default="next")
parser.add_argument('--next', dest='direction', action='store_const',
                    help='swich to the next workspace (default)',  const="next", default="next")

args = parser.parse_args()

workspaces = []
for workspace in i3.get_workspaces():
    if workspace['visible']:
        workspaces.append(workspace)

workspaces.extend(workspaces)

if args.direction == "prev":
    workspaces.reverse()

switch_to = False
for workspace in workspaces:
    if switch_to:
        i3.workspace(workspace['name'])
        break
    if workspace['focused']:
        switch_to = True

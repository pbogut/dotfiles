#!/usr/bin/python2.7
# Display all workspaces on panel
import i3
import sys

o = sys.stdout

for output in i3.get_outputs():
    if output['active'] == True:
        if output['rect']['x'] == 0:
            left_output = output['name']
        if output['rect']['x'] > 0:
            right_output = output['name']

left_workspaces = []
right_workspaces = []

for workspace in i3.get_workspaces():
    if workspace['output'] == left_output:
        left_workspaces.append(workspace)
    if workspace['output'] == right_output:
        right_workspaces.append(workspace)

for workspace in left_workspaces:
    if workspace['focused'] == True:
        o.write('[*' + workspace['name'] + '*]')
    else:
        o.write('[ ' + workspace['name'] + ' ]')

o.write(' | ')

for workspace in right_workspaces:
    if workspace['focused'] == True:
        o.write('[*' + workspace['name'] + '*]')
    else:
        o.write('[ ' + workspace['name'] + ' ]')

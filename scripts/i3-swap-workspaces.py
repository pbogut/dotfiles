#!/usr/bin/python2.7
# Swap workspaces on two monitors
import i3

# collect active outputs
to_be_swapped = [output for output in i3.get_outputs() if output['active']]
# only swap when there are two active outputs
if len(to_be_swapped) == 2:
    for output in to_be_swapped:
        i3.workspace(output['current_workspace'])
        i3.command('move', 'workspace to output right')

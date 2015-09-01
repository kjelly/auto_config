#!/usr/bin/env python
import sys
import i3

output_target = sys.argv[1]

outputs = i3.get_outputs()
for index, data in enumerate(outputs):
    if data['name'] == output_target:
        output_target_index = index

original_workspace = outputs[output_target_index]['current_workspace']

workspaces = i3.get_workspaces()

for i in xrange(0, 10):
    try:
        i3.workspace(workspaces[i]['name'])
        i3.move__workspace__to__output(output_target)
    except IndexError as e:
        pass


i3.workspace(original_workspace)

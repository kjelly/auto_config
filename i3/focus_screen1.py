#!/usr/bin/python2.7

import i3
outputs = i3.get_outputs()

# set current workspace to output 0
i3.workspace(outputs[1]['current_workspace'])


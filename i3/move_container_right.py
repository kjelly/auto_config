#!/usr/bin/env python

import i3
outputs = i3.get_outputs()

# set current workspace to output 0
workspace = outputs[0]['current_workspace']

# ..and move it to the other output.
# outputs wrap, so the right of the right is left ;)
print workspace
i3.move__container__to__workspace(workspace)

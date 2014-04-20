#!/usr/bin/env python

import i3
outputs = i3.get_outputs()

for i in xrange(0, 10):
    try:
        workspace_number = outputs[i]['current_workspace']
        print 'screen %d: %s' % (i, workspace_number)
    except IndexError as e:
        pass



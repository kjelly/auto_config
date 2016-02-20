#!/usr/bin/env python
import i3
import os
import subprocess
import sys
from lib import dmenu, dmenu_cmd


if __name__ == '__main__':
    scratchpad = i3.filter(name="__i3_scratch")[0]
    nodes = scratchpad["floating_nodes"]
    windows = [i for i in i3.filter(tree=nodes, nodes=[])]
    window_titles = ['%s #%s' % (i.get('name'), i.get('window')) for i in windows]
    answer = dmenu(window_titles, dmenu_cmd('select window: '))
    if answer:
        i3.scratchpad("show", id=answer.split('#')[-1])
        if len(sys.argv) > 1 and sys.argv[1] == '1':
            # floating mode, do nothing
            pass
        else:
            i3.floating('disable')


#!/usr/bin/env python
import i3
import os
import subprocess
import sys

def dmenu(options, dmenu):
    '''Call dmenu with a list of options.'''

    cmd = subprocess.Popen(dmenu,
                           shell=True,
                           stdin=subprocess.PIPE,
                           stdout=subprocess.PIPE,
                           stderr=subprocess.PIPE)
    stdout, _ = cmd.communicate('\n'.join(options).encode('utf-8'))
    return stdout.decode('utf-8').strip('\n')


if __name__ == '__main__':
    scratchpad = i3.filter(name="__i3_scratch")[0]
    nodes = scratchpad["floating_nodes"]
    windows = [i for i in i3.filter(tree=nodes, nodes=[])]
    window_titles = ['%s #%s' % (i.get('name'), i.get('window')) for i in windows]
    answer = dmenu(window_titles, 'dmenu -i -b -l 30')
    if answer:
        i3.scratchpad("show", id=answer.split('#')[-1])
        if len(sys.argv) > 1 and sys.argv[1] == '1':
            # floating mode, do nothing
            pass
        else:
            i3.floating('disable')


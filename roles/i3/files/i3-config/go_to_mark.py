#!/usr/bin/env python
import i3
import os
import subprocess

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
    marks = i3.get_marks()
    answer = dmenu(marks, 'dmenu -i -b -l 30')
    if answer:
        os.system('''i3-msg '[con_mark="%s"] focus' ''' % answer)


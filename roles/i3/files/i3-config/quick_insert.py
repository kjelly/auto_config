#!/usr/bin/env python3
import i3
import os
import subprocess
from os.path import expanduser


def dmenu(options, dmenu):
    '''Call dmenu with a list of options.'''

    cmd = subprocess.Popen(dmenu,
                           shell=True,
                           stdin=subprocess.PIPE,
                           stdout=subprocess.PIPE,
                           stderr=subprocess.PIPE)
    stdout, _ = cmd.communicate('\n'.join(options).encode('utf-8'))
    return stdout.decode('utf-8').strip('\n')


def shellquote(s):
    return "'" + s.replace("'", "'\\''") + "'"


if __name__ == '__main__':
    wid = [i.get('window') for i in i3.filter(nodes=[]) if i.get('focused')][0]

    home = expanduser("~")

    with open(os.path.join(home, '.i3', 'quick_insert.txt'), 'r') as ftr:
        text = ftr.readlines()
    text = [i.strip() for i in text if len(i.strip()) != 0]

    answer = dmenu(text, 'dmenu -i -b -l 30')
    if answer:
        os.system('''xdotool type --window %s  %s ''' % (wid, shellquote(answer)))


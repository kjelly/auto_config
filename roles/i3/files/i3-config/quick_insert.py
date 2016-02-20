#!/usr/bin/env python3
import i3
import os
import subprocess
from os.path import expanduser
from lib import dmenu, dmenu_cmd

def shellquote(s):
    return "'" + s.replace("'", "'\\''") + "'"


if __name__ == '__main__':
    wid = [i.get('window') for i in i3.filter(nodes=[]) if i.get('focused')][0]

    home = expanduser("~")

    with open(os.path.join(home, '.i3', 'quick_insert.txt'), 'r') as ftr:
        text = ftr.readlines()
    text = [i.strip() for i in text if len(i.strip()) != 0]

    answer = dmenu(text, dmenu_cmd('select word: '))
    if answer:
        os.system('''xdotool type --window %s  %s ''' % (wid, shellquote(answer + ' ')))


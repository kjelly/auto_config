#!/usr/bin/env python3
import i3
import os
import subprocess
from os.path import expanduser
from lib import dmenu, dmenu_cmd
import re


def shellquote(s):
    return "'" + s.replace("'", "'\\''") + "'"


def main():
    wid = [i.get('window') for i in i3.filter(nodes=[]) if i.get('focused')][0]

    home = expanduser("~")

    with open(os.path.join(home, '.config', 'fish', 'fish_history'), 'r') as ftr:
        raw_data = ftr.readlines()
    data = [i[6:-1] for i in raw_data if i.startswith('- cmd:')]

    answer = dmenu(reversed(data[20:]), dmenu_cmd('select word: ')).strip()
    if answer:
        os.system('''xdotool type --window %s  %s ''' % (wid, shellquote(answer + ' ')))
        if answer[-1] == ';':
            os.system('''xdotool key --window %s  Return ''' % (wid))

if __name__ == '__main__':
    main()

#!/usr/bin/env python3
import i3
import os
import subprocess
from os.path import expanduser
import sys


def shellquote(s):
    return "'" + s.replace("'", "'\\''") + "'"


if __name__ == '__main__':
    try:
        term = 'xfce4-terminal'
        wid, instance, title = [(i.get('window'), i.get('window_properties').get('instance'), i.get('window_properties').get('title')) for i in i3.filter(nodes=[]) if i.get('focused')][0]
        w = [i for i in i3.filter(nodes=[]) if i.get('focused')][0]

        if 'term' in instance and (' fish ' in title or ' zsh ' in title or ' bash ' in title):
            cmd = '%s --working-directory=(pwd)' % term
            os.system('''xdotool type --window %s  %s ''' % (wid, shellquote(cmd)))
            os.system('''xdotool key --window %s  Return ''' % wid)
        else:
            os.system('''i3-msg "exec %s" ''' % term)
    except:
        os.system('''i3-msg "exec %s" ''' % term)



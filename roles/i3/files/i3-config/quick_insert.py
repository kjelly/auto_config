#!/usr/bin/env python3
import i3
import os
import subprocess
from os.path import expanduser
from lib import dmenu, dmenu_cmd
import re


def shellquote(s):
    return "'" + s.replace("'", "'\\''") + "'"


def ask_for_variable(template_str):
    pattern = re.compile('#\([a-zA-Z0-9]+\)|#[a-zA-Z0-9]+')

    result = pattern.search(template_str)
    while result:
        variable = result.group(0)
        answer = dmenu([], dmenu_cmd('%s-> %s:' % (template_str, variable[1:])))
        template_str = template_str.replace(variable, answer)
        result = pattern.search(template_str)
    return template_str





def main():
    wid = [i.get('window') for i in i3.filter(nodes=[]) if i.get('focused')][0]

    home = expanduser("~")

    with open(os.path.join(home, '.i3', 'quick_insert.txt'), 'r') as ftr:
        text = ftr.readlines()
    text = [i.strip() for i in text if len(i.strip()) != 0]

    answer = dmenu(text, dmenu_cmd('select word: ')).strip()
    answer = ask_for_variable(answer)
    if answer:
        os.system('''xdotool type --window %s  %s ''' % (wid, shellquote(answer + ' ')))
        if answer[-1] == ';':
            os.system('''xdotool key --window %s  Return ''' % (wid))

if __name__ == '__main__':
    main()

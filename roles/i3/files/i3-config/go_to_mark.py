#!/usr/bin/env python
import i3
import os
import subprocess
from lib import dmenu, dmenu_cmd


if __name__ == '__main__':
    marks = i3.get_marks()
    answer = dmenu(marks, dmenu_cmd('select mark: '))
    if answer:
        os.system('''i3-msg '[con_mark="%s"] focus' ''' % answer)


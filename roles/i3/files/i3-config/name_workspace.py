#!/usr/bin/env python3
import i3
import subprocess
import os
from collections import Counter
from lib import dmenu, dmenu_cmd



config_path = os.path.join(os.path.expanduser("~"), '.i3_workspace_name_history')


def read_history():
    if not os.path.exists(config_path):
        return []
    with open(config_path, 'r') as ftr:
        lines = ftr.readlines()
    return [ i[0] for i in Counter(lines).most_common() if i[0].strip() != '']


def write_history(name):
    with open(config_path, 'a+') as ftr:
        ftr.write('%s\n' % name)


def main():
    workspaces = i3.get_workspaces()
    for i in workspaces:
        if i['focused']:
            focused_workspace_num = i['num']
    answer = dmenu(read_history(), dmenu_cmd('Name: ')).strip()
    if len(answer) > 0:
        i3.rename__workspace__to('"%d: %s"' % (focused_workspace_num, answer))
        write_history(answer)


if __name__ == '__main__':
    main()

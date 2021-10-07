#!/usr/bin/env python3

import os
import subprocess
import sys


if __name__ == '__main__':
    argv = sys.argv
    if len(argv) == 1:
        workspace_file = os.path.expanduser('~/.workspaces')
        paths = []
        chooses = []
        if os.path.exists(workspace_file):
            with open(workspace_file) as ftr:
                paths = [i.strip()
                         for i in ftr.readlines() if len(i.strip()) > 0]

        for i in paths:
            i = os.path.expanduser(i)
            if i.endswith('*'):
                i = i[:-1]
                for j in os.listdir(i):
                    real_path = os.path.join(i, j)
                    if os.path.isdir(real_path):
                        chooses.append(real_path)
            else:
                chooses.append(i)
        print('\n'.join(chooses))
    else:
        subprocess.run(
            ['i3-msg', f'exec "alacritty --working-directory {argv[1]}"'],
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE)

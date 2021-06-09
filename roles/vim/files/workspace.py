#!/usr/bin/env python3

import sys
import os
import subprocess

paths = [
]
path_file = os.path.expanduser('~/.workspaces')

if len(sys.argv) > 1:
    paths = sys.argv[1:]
elif os.path.exists(path_file):
    with open(path_file) as ftr:
        paths = [i.strip() for i in ftr.readlines() if len(i.strip()) > 0]

chooses = []

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


if __name__ == '__main__':
    fzf = subprocess.Popen(["fzf"], stdin=subprocess.PIPE, stdout=subprocess.PIPE)
    stdout_bytes, stderr_bytes = fzf.communicate(
        '\n'.join(chooses).encode('utf-8'))
    stdout = stdout_bytes.decode('utf-8').strip()
    stdout = os.path.expanduser(stdout)
    old_title = '%s-%s' % ('fish', os.getcwd())
    if os.path.exists(stdout):
        os.system("tmux rename-window nvim-%s" % stdout)
        if os.path.isdir(stdout):
            os.chdir(stdout)
            os.system("vim")
        else:
            os.system("vim '%s'" % stdout)
        os.system("tmux rename-window %s" % old_title)

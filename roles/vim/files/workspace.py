#!/usr/bin/env python3

import sys
import os
import subprocess
import argparse


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='Process some integers.')
    parser.add_argument('-p', '--print', action='store_true')
    parser.add_argument('dir', metavar='d', type=str, nargs='*')

    args = parser.parse_args()

    paths = [
    ]
    path_file = os.path.expanduser('~/.workspaces')

    if len(args.dir) > 0:
        paths = args.dir
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

    fzf = subprocess.Popen(
        ["fzf"], stdin=subprocess.PIPE, stdout=subprocess.PIPE)
    stdout_bytes, stderr_bytes = fzf.communicate(
        '\n'.join(chooses).encode('utf-8'))
    stdout = stdout_bytes.decode('utf-8').strip()
    stdout = os.path.expanduser(stdout)
    old_title = '%s-%s' % ('fish', os.getcwd())
    if len(stdout.strip()) == 0:
        sys.exit(1)
    elif os.path.exists(stdout):
        if args.print:
            print(stdout)
            sys.exit(0)
        os.system("tmux rename-window nvim-%s" % stdout)
        if os.path.isdir(stdout):
            os.chdir(stdout)
            os.system("vim")
        else:
            os.system("vim '%s'" % stdout)
        os.system("tmux rename-window %s" % old_title)
    else:
        sys.exit(1)

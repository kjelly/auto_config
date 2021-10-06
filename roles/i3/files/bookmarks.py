#!/usr/bin/env python3

import os
import subprocess
import sys

bookmark_file = os.path.expanduser('~/bookmarks.txt')
if len(sys.argv) == 1 and os.path.exists(bookmark_file):
    with open(bookmark_file, 'r') as ftr:
        print(ftr.read().strip())
else:
    subprocess.run(
        ['i3-msg', f'exec bb "{sys.argv[1]}"'],
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE)

#!/usr/bin/env python3
import subprocess
import sys

commands = [';kill']
if len(sys.argv) == 1:
    for i in commands:
        print(i)
elif sys.argv[1] == ';kill':
    subprocess.run(
        ['i3-msg', f'{sys.argv[1][1:]}'],
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE)
else:
    subprocess.run(
        ['i3-msg', f'exec bb "go {sys.argv[1]}"'],
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE)

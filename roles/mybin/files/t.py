#!/usr/bin/env python

import os
import sys
import subprocess


def list_all_sessions():
    ret = []
    try:
        output = subprocess.check_output(["tmux", "ls"])
        lines = output.strip().split('\n')
        for i in lines:
            session_name = i.split(':')[0]
            ret.append(session_name)

    except subprocess.CalledProcessError:
        pass
    return ret


def main():
    session_list = list_all_sessions()
    if len(sys.argv) == 1:
        print(session_list)
        return
    argv1 = sys.argv[1]
    if argv1 == '#':
        if len(session_list) == 0:
            os.system("tmux")
        else:
            os.system("tmux attach #")
    if argv1 in session_list:
        os.system("tmux attach -t %s" % argv1)
    else:
        os.system("tmux new -s %s" % argv1)


if __name__ == "__main__":
    main()

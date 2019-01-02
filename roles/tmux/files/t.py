#!/usr/bin/env python

import argparse
import os
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
    parser = argparse.ArgumentParser(description='Tmux wrapper')
    parser.add_argument('name', type=str, nargs="?")
    parser.add_argument('--list', '-l', action='store_true')
    parser.add_argument('--kill', '-k')
    args = parser.parse_args()
    session_list = list_all_sessions()
    tmux = 'tmux'
    if args.list:
        print(session_list)
        return
    elif args.kill is not None:
        os.system("%s kill-session -t %s" % (tmux, args.kill))
    elif args.name is None:
        os.system("%s attach #" % (tmux))
    else:
        name = args.name
        if name in session_list:
            os.system("%s attach -t %s" % (tmux, name))
        else:
            os.system("%s new -s %s" % (tmux, name))


if __name__ == "__main__":
    main()

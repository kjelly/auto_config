#!/usr/bin/env python3

import argparse
from subprocess import check_output, check_call
from os.path import abspath, dirname, isdir
import subprocess


def fuzzy_find(path):
    output = check_output('tree -if --noreport %s |fzf' % path, shell=True)
    return abspath(output.strip())


def main():
    parser = argparse.ArgumentParser(description='Process some integers.')
    parser.add_argument('cmd', type=str, nargs='+',
                       help='an integer for the accumulator')
    parser.add_argument('-s', dest='string', type=str, nargs='+',
                       help='sum the integers (default: find the max)')
    args = parser.parse_args()
    cmd = []
    try:
        for i in args.cmd:
            if '@' == i[0]:
                if args.string:
                    path = fuzzy_find(args.string.pop(0))
                else:
                    path = fuzzy_find('.')
                if '@d' == i and not isdir(path):
                    cmd.append(dirname(path))
                else:
                    cmd.append(path)
            else:
                cmd.append(i)
        print(' '.join(cmd))
        check_call(cmd)
    except subprocess.CalledProcessError:
        pass


if __name__ == '__main__':
    main()

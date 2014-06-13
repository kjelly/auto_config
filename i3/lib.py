#! /usr/bin/python

from subprocess import check_output
import sys
import json
import random


def list_screen():
    output = check_output("xrandr | grep ' connect'", shell=True)
    output = map(lambda s: s.split(' ')[0], output.split('\n'))
    output = filter(lambda s: len(s) != 0, output)
    return output


def get_first_args():
    try:
        if len(sys.argv) > 1:
            return int(sys.argv[1], 10)
    except Exception as e:
        return 0
    return 0


def get_screen():
    screen_number = get_first_args()
    all_screen = list_screen()
    if screen_number > len(all_screen):
        screen_number = 0
    return all_screen[screen_number]

def rename_workspace(a, b):
    if a == b:
        return False
    output = check_output("i3-msg 'rename workspace %d to %d'" % (a, b), shell=True)
    return json.loads(output)

def swap_workspace(a, b):
    if a == b:
        return False
    tmp = random.randint(100, 1000)
    rename_workspace(a, tmp)
    rename_workspace(b, a)
    rename_workspace(tmp, b)
    return True

def get_workspace_info():
    output = check_output("i3-msg -t get_workspaces", shell=True)
    return json.loads(output)


def get_active_workspace():
    obj = get_workspace_info()
    for i in obj:
        if i['focused']:
            return i


if __name__ == '__main__':
    print list_screen()

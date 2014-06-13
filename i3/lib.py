#! /usr/bin/python

from subprocess import check_output
import sys


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


if __name__ == '__main__':
    print list_screen()

#! /usr/bin/python


from lib import get_screen
import os


if __name__ == '__main__':
    os.system("i3-msg 'move container to output %s'" % get_screen())

#! /usr/bin/python


from lib import get_screen
import os


if __name__ == '__main__':
    os.system("i3-msg 'focus output %s'" % get_screen())

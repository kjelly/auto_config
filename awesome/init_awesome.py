#! /usr/bin/env python

import os
from subprocess import check_output


def grep(pattern, data):
    data_list = data.split('\n')
    return [i for i in data_list if i.find(pattern) != -1]


def start_process(program):
    process_list = check_output(['ps', 'aux'])
    result = grep(program, process_list)
    if len(result) == 0:
        print program



def start_nm_applet():
    start_process('nm-applet')


def start_nm_applet():
    start_process('gnome-sound-applet')


def disable_lvds1():
    result = check_output(['xrandr'])
    if result.find('VGA1 connected') != -1:
        print 'xrandr --output LVDS1 --off'
        print 'xrandr --output VGA1 --mode 1920x1080'


try:
    start_nm_applet()
    disable_lvds1()
except:
    # just ouput command, not error.
    pass

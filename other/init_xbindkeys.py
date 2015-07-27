#! /usr/bin/env python
from common.dir_operator import get_home_dir, make_link
import os.path
from os import listdir

name = 'send_key.py'
def make_link_for_file(name):
     target = os.path.join(get_home_dir(), name)

     config_parent_path = os.path.dirname(__file__)
     config_path = os.path.join(config_parent_path, name)
     make_link(config_path, target)
make_link_for_file('send_key.py')
make_link_for_file('.xbindkeysrc')

os.system("sudo apt-get install xbindkeys xvkbd")
os.system("sudo pip install psutil")


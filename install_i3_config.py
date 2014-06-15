#! /usr/bin/env python
from common.dir_operator import get_home_dir, make_link
import os.path
from os import listdir

target = os.path.join(get_home_dir(), '.i3')

config_parent_path = os.path.dirname(__file__)
config_path = os.path.join(config_parent_path, 'i3')
make_link(config_path, target)

os.system("sudo apt-get -y install i3 i3status")
os.system("sudo apt-get -y install terminator")
os.system("sudo apt-get -y install python-pip")
os.system("sudo apt-get -y install dmenu")
os.system("sudo apt-get -y install xfce4-panel")
os.system("sudo apt-get -y install gnome-control-center")
os.system("sudo pip install py3status")
os.system("sudo pip install i3-py")
os.system("sudo pip install quickswitch-i3")


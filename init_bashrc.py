#! /usr/bin/env python
from common.dir_operator import get_home_dir, make_link
import os.path
from os import listdir

target = os.path.join(get_home_dir(), '.bashrc')

config_parent_path = os.path.dirname(__file__)
config_path = os.path.join(config_parent_path, '.bashrc')
make_link(config_path, target)

os.chdir(get_home_dir())
os.system("git clone https://github.com/magicmonty/bash-git-prompt.git .bash-git-prompt")


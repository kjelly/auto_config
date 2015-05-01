#! /usr/bin/env python
from common.dir_operator import get_home_dir, make_link
import os.path
from os import listdir

target = os.path.join(get_home_dir(), '.i3')

config_path = os.path.abspath(os.path.dirname(__file__))

make_link('%s/atom/config.cson' % config_path, '%s/.atom/config.cson' % get_home_dir())
make_link('%s/atom/keymap.cson' % config_path, '%s/.atom/keymap.cson' % get_home_dir())

os.system("apm install  autocomplete-plus")
os.system("apm install  language-restructuredtext")
os.system("apm install  language-scala")

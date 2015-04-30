#! /usr/bin/env python
import os
import os.path
from common.dir_operator import make_link, get_home_dir, get_project_dir


def sudo(cmd):
    os.system("sudo %s" % cmd)


def apt_get_install(package):
    cmd = "apt-get -y install %s" % package
    sudo(cmd)


def pip_install(package):
    cmd = "pip install  %s" % package
    sudo(cmd)


apt_get_install("build-essential")
apt_get_install("python-dev")
apt_get_install("wireless-tools")
apt_get_install("vim-gtk")
apt_get_install("golang")
apt_get_install("scala")
apt_get_install("python-pip")
apt_get_install("tmux")
pip_install("virtualenvwrapper")
make_link(os.path.join('gitconfig'),os.path.join(get_home_dir(), '.gitconfig'))
make_link(os.path.join('tmux.conf'),os.path.join(get_home_dir(), '.tmux.conf'))

#! /usr/bin/env python
import os


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
pip_install("virtualenvwrapper")

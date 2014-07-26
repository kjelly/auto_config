#! /usr/bin/env python
import os


def sudo(cmd):
    os.system("sudo %s" % cmd)


def apt_get_install(package):
    cmd = "apt-get -y install %s" % package
    sudo(cmd)


apt_get_install("virtualbox-guest-dkms virtualbox-guest-utils virtualbox-guest-x11")

#! /usr/bin/env python
import os


def sudo(cmd):
    os.system("sudo %s" % cmd)


def apt_get_install(package):
    cmd = "apt-get -y install %s" % package
    sudo(cmd)


apt_get_install("git i3 i3-wm i3status vim virtualbox-qt virtualbox-dkms virtualbox-4.3 virtualbox-nonfree")
apt_get_install("virtualbox-nonfree")
apt_get_install("pcmanfm pcmanx-gtk2 vifm")
apt_get_install("scim scim-chewing")
apt_get_install("workrave")

#! /usr/bin/env python
#-*- coding: utf-8 -*-
import getpass
import os

passwd = getpass.getpass("Please input samba password.")
returncode = os.system("sudo mount -t cifs //192.168.1.131/nas nas/ -o username=pi,password=%s,uid=1000,gid=1000" % passwd)
returncode = 0
if returncode == 0:
    os.system("sudo mount -o bind nas/sda1/linux_download ~/下載/")

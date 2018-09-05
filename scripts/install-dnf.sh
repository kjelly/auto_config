#! /bin/bash

dnf -y install python-pip python-devel git vim python-dnfdaemon python-dnf-plugins-core redhat-rpm-config libselinux-python gcc-c++ libxml2-devel
dnf -y groupinstall "Development Tools"
dnf -y builddep ansible
pip install ansible

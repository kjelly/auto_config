#! /bin/bash
sudo yum  install -y epel-release
wget https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
sudo yum  install  -y epel-release-7.noarch.rpm
yum install python-pip python-devel git vim python-yumdaemon python-yum-plugins-core redhat-rpm-config libselinux-python gcc-c++
yum groupinstall "Development Tools"
yum builddep ansible
pip install ansible

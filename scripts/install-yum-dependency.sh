#! /bin/bash
sudo yum install -y wget
sudo yum  install -y epel-release
wget https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
sudo yum  install  -y epel-release-7.noarch.rpm
sudo yum install -y  python-setuptools python-devel git vim python-yumdaemon python-yum-plugins-core redhat-rpm-config libselinux-python gcc-c++
sudo yum groupinstall -y "Development Tools"
sudo easy_install pip
sudo pip install ansible

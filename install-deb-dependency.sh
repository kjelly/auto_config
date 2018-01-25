#! /bin/bash
export LC_ALL=C
sudo apt-get dist-upgrade
sudo apt-get install -y python-dev git python-setuptools libffi-dev libssl-dev
sudo apt-get build-dep -y ansible python-cryptography
sudo easy_install pip
sudo pip install --upgrade setuptools
sudo pip install ansible
sudo pip install markupsafe
sudo pip install cryptography

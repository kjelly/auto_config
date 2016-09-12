#! /bin/bash
export LC_ALL=C
sudo apt-get install -y python-dev git python-pip libffi-dev libssl-dev
sudo apt-get build-dep -y ansible python-cryptography
sudo pip install ansible
sudo pip install markupsafe
sudo pip install cryptography

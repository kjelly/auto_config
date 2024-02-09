#! /bin/bash
export LC_ALL=C
sudo apt update
sudo apt-get dist-upgrade -y
sudo apt-get install -y libffi-dev libssl-dev python3-setuptools curl ansible


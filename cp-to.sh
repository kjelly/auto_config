#!/bin/bash
sudo cp -rf ~/auto_config /home/$1/auto_config
sudo chown -R $1:$1 /home/$1/auto_config


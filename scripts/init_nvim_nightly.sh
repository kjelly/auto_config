#!/bin/bash

sudo curl -fL https://github.com/neovim/neovim/releases/download/nightly/nvim.appimage -o /opt/nvim.appimage.nightly
sudo chmod +x /opt/nvim.appimage.nightly
cd /opt/
sudo rm -rf /opt/squashfs-root
sudo /opt/nvim.appimage.nightly --appimage-extract
sudo rm -rf /opt/neovim.nightly
sudo mv squashfs-root neovim.nightly
sudo find /opt/neovim.nightly/ -type d -exec chmod go+rx {} \;
cd /usr/local/bin
sudo ln -s /opt/neovim.nightly/AppRun nvim.nightly
sudo rm -rf  /usr/share/nvim/runtime/colors/*

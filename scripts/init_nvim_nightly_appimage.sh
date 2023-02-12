#!/bin/bash

sudo curl -fL https://github.com/neovim/neovim/releases/download/nightly/nvim.appimage -o /opt/nvim.appimage.nightly
sudo chmod +x /opt/nvim.appimage.nightly
cd /opt/
sudo cp /opt/nvim.appimage.nightly /usr/bin/nvim.nightly

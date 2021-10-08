#!/bin/bash
version=$(git -c 'versionsort.suffix=-' \
    ls-remote --exit-code --refs --sort='version:refname' --tags https://github.com/neovim/neovim '*.*.*' \
    | tail --lines=1 \
    | cut --delimiter='/' --fields=3)
echo sudo curl -fL https://github.com/neovim/neovim/releases/download/$version/nvim.appimage -o /opt/nvim.appimage
sudo chmod +x /opt/nvim.appimage

cd /opt/
sudo rm -rf /opt/squashfs-root
sudo /opt/nvim.appimage --appimage-extract
sudo rm -rf /opt/neovim
sudo mv squashfs-root neovim
cd /usr/local/bin
sudo find /opt/neovim/ -type d -exec chmod go+rx {} \;
sudo ln -s /opt/neovim/AppRun nvim


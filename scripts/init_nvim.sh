#!/bin/bash
killall nvim
version=$(git -c 'versionsort.suffix=-' \
    ls-remote --exit-code --refs --sort='version:refname' --tags https://github.com/neovim/neovim '*.*.*' \
    | tail --lines=1 \
    | cut --delimiter='/' --fields=3)
echo $version
#sudo curl -fL https://github.com/neovim/neovim/releases/download/$version/nvim.appimage -o /opt/nvim.appimage
#sudo chmod +x /opt/nvim.appimage
#sudo cp /opt/nvim.appimage /bin/nvim
wget https://github.com/neovim/neovim/releases/download/$version/nvim-linux64.deb -O nvim.deb
sudo dpkg -i nvim.deb

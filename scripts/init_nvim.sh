#!/bin/bash
killall nvim
version=$(git -c 'versionsort.suffix=-' \
    ls-remote --exit-code --refs --sort='version:refname' --tags https://github.com/neovim/neovim '*.*.*' \
    | tail --lines=1 \
    | cut --delimiter='/' --fields=3)
echo $version


sudo curl -L https://github.com/neovim/neovim/releases/download/$version/nvim-linux-$(uname -p).appimage --output /usr/local/bin/nvim
sudo chmod +x /usr/local/bin/nvim

#!/bin/bash

sudo curl -fL https://github.com/neovim/neovim/releases/download/v0.3.0/nvim.appimage -o /opt/nvim.appimage
sudo chmod +x /opt/nvim.appimage
cd /opt/
sudo /opt/nvim.appimage --appimage-extract
sudo rm -rf /opt/neovim
sudo mv squashfs-root neovim
cd /usr/local/bin
sudo find /opt/neovim/ -type d -exec chmod o+x {} \;
sudo ln -s /opt/neovim/AppRun nvim

mv ~/.config/nvim/init.vim ~/.config/nvim/init.vim.`date +%F_%R`

curl -fLo ~/.vim/autoload/plug.vim --create-dirs \
    https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim

mkdir -p ~/.config/nvim/autoload/

cp ~/.vim/autoload/plug.vim ~/.config/nvim/autoload/plug.vim

curl https://myvimrc.herokuapp.com/vimrc?programming=1 -o ~/.config/nvim/init.vim

git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf

~/.fzf/install --all

touch  ~/.vim_custom.vim

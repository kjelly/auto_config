#!/bin/bash

sudo curl -fL https://github.com/neovim/neovim/releases/download/v0.2.2/nvim.appimage -o /usr/bin/nvim

sudo chmod +x /usr/bin/nvim

curl -fLo ~/.vim/autoload/plug.vim --create-dirs \
    https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim

mkdir -p ~/.config/nvim/autoload/

cp ~/.vim/autoload/plug.vim ~/.config/nvim/autoload/plug.vim

curl https://myvimrc-205113.appspot.com/?programming=1 -o ~/.config/nvim/init.vim

git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf

~/.fzf/install --all

touch  ~/.vim_custom.vim

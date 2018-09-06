#!/bin/bash

cd ~
mkdir ~/.config
cp -r /home/$1/.config/nvim ~/.config
cp -r /home/$1/.fzf ~/

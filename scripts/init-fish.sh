#!/usr/bin/env bash

version=4.0.1
wget https://github.com/fish-shell/fish-shell/releases/download/$version/fish-static-$(uname -m)-$version.tar.xz -O /tmp/fish.tar.xz

mkdir -p /tmp/fish/ ~/bin/
tar xvf /tmp/fish.tar.xz -C /tmp/fish
cp /tmp/fish/* ~/bin



#!/bin/bash
xcode-select --install

/usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
brew install ansible
brew install eclocal
brew install libtool
brew install cmake


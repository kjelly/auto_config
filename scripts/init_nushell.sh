#!/bin/bash

sudo apt update;sudo apt install -y git curl

cd /tmp

# get the latest version of nushell version
curl -s https://api.github.com/repos/nushell/nushell/releases/latest \
| grep -e "browser_download_url.*x86_64-unknown-linux-musl.tar.gz" \
 | cut -d : -f 2,3 \
 | tr -d \" \
 | wget -qi - -O nushell.tar.gz

mkdir -p ~/bin
# extract nushell and move it to ~/bin
# this will overwrite any existing nushell installation
tar -xzf /tmp/nushell.tar.gz -C ~/bin --strip-components=1

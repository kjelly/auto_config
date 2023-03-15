#!/bin/bash

cd /tmp

# get the latest version of nushell version
curl -s https://api.github.com/repos/nushell/nushell/releases/latest \
| grep -e "browser_download_url.*x86_64-unknown-linux-musl.tar.gz" \
 | cut -d : -f 2,3 \
 | tr -d \" \
 | wget -qi - -O nushell.tar.gz

mkdir -p ~/bin
tar zxvf /tmp/nushell.tar.gz --wildcards '*/nu' -C ~/bin

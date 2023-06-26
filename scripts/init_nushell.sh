#!/bin/bash

sudo apt update;sudo apt install -y git

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

mkdir -p ~/.config/nushell

git clone https://github.com/nushell/nu_scripts ~/nu_scripts/

wget -O ~/.config/nushell/config.nu https://fonts.kjelly.tw/default_config.nu

wget -O ~/.config/nushell/env.nu https://fonts.kjelly.tw/default_env.nu

touch ~/.atuin.nu ~/.zoxide.nu ~/.carapace.nu

touch ~/.config/custom.nu
wget -O- https://raw.githubusercontent.com/kjelly/auto_config/master/roles/nushell/files/config.nu | tee -a ~/.config/nushell/config.nu

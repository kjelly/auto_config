#!/bin/bash

# Get the latest pueue version

curl -s https://api.github.com/repos/Nukesor/pueue/releases/latest \
| grep -e "browser_download_url.*" \
| grep -e "pueue-linux-x86_64" \
 | cut -d : -f 2,3 \
 | tr -d \" \
 | wget -qi - -O /tmp/pueue

curl -s https://api.github.com/repos/Nukesor/pueue/releases/latest \
| grep -e "browser_download_url.*" \
| grep -e "pueued-linux-x86_64" \
 | cut -d : -f 2,3 \
 | tr -d \" \
 | wget -qi - -O /tmp/pueued

chmod +x /tmp/pueue /tmp/pueued

mkdir -p $HOME/.config/systemd/user

curl -s https://api.github.com/repos/Nukesor/pueue/releases/latest \
| grep -e "browser_download_url.*" \
| grep -e "systemd" \
 | cut -d : -f 2,3 \
 | tr -d \" \
 | wget -qi - -O $HOME/.config/systemd/user/pueue.service

mv /tmp/pueue ~/bin/
mv /tmp/pueued /usr/bin/

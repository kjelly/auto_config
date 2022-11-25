#!/bin/bash

sudo='sudo'
$sudo curl -fL https://github.com/helix-editor/helix/releases/download/22.08.1/helix-22.08.1-x86_64.AppImage -o /opt/hx
chmod +x /opt/hx
cd /opt
$sudo rm -rf /opt/squashfs-root
$sudo /opt/hx --appimage-extract
$sudo mv squashfs-root hx-dir
$sudo find /opt/hx-dir/ -type d -exec chmod go+rx {} \;
cd /usr/local/bin
$sudo ln -s /opt/hx-dir/AppRun hx


#!/bin/bash

font=`fc-list :mono|grep Nerd|choose -f ':' 1|shuf|head -n 1|sed -e 's/^[[:space:]]*//'`
size=16

cp ~/.alacritty.yml ~/a.yaml
yq e ".font.normal.family=\"$font\"" ~/a.yaml -i
yq e ".font.bold.family=\"$font\"" ~/a.yaml -i
yq e ".font.italic.family=\"$font\"" ~/a.yaml -i
yq e ".font.bold_italic.family=\"$font\"" ~/a.yaml -i
yq e ".font.size=$size" ~/a.yaml -i
yq e ".env.TERM=xterm-256color" ~/a.yaml -i

cp ~/a.yaml ~/.alacritty.yml


crudini --set ~/.config/xfce4/terminal/terminalrc 'Configuration' 'FontName' "$font $size"

#!/usr/bin/bash

curl -fsSL https://starship.rs/install.sh | sh

cd "$(dirname "$0")"
mkdir -p ~/.config
if [ -f ./startship.toml ]; then
  cp ./startship.toml ~/.config/starship.toml
else
  wget https://raw.githubusercontent.com/kjelly/auto_config/refs/heads/master/scripts/starship.toml -O ~/.config/starship.toml
fi

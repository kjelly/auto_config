#!/usr/bin/env bash

curl https://mise.run | sh

mkdir -p ~/.config/nushell/autoload/
mise activate nu | save -f ~/.config/nushell/autoload/mise.nu

cat <<EOF > ~/.config/mise/config.toml

[tools]
age = "latest"
helm = "latest"
k9s = "latest"
kubectx = "latest"
navi = "latest"
opentofu = "latest"
starship = "latest"
terraform = "latest"
kubens = "latest"
ripgrep = "latest"
usql = "latest"
fzf = "latest"
gron = "latest"
k3sup = "latest"
act = "latest"
mprocs = "latest"
btop = "latest"
direnv = "latest"
tmux = "latest"

EOF


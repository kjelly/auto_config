#!/usr/bin/bash

curl -fsSL https://starship.rs/install.sh | sh

cat << EOF > ~/.config/starship.toml
[character]
success_symbol = '[➜](bold green) '
error_symbol = '[✗](bold red) '

[aws]
symbol = '☁️ 🅰 '
[azure]
symbol = '☁️ ﴃ '
[gcloud]
symbol = '☁️ 🇬️ '
[kubernetes]
disabled = false
[python]
disabled = true
[nodejs]
disabled = true
[status]
disabled = false
[memory_usage]
disabled = false
[opa]
disabled = true
[lua]
disabled = true
[java]
disabled = true
[hostname]
ssh_only = false
EOF


#!/usr/bin/bash

curl -fsSL https://starship.rs/install.sh | sh

cat << EOF > ~/.config/starship.toml
[directory]
format = '📁[$path]($style)[$read_only]($read_only_style) '
[character]
success_symbol = '[➜](bold green) '
error_symbol = '[✗](bold red) '

[aws]
symbol = '☁️ AWS '
[azure]
symbol = '☁️ AZ '
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


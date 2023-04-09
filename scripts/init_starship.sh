curl -fsSL https://starship.rs/install.sh | bash

cat << EOF >> ~/.config/starship.toml
[character]
success_symbol = '[✅](bold green) '
error_symbol = '[❌](bold red) '
[aws]
symbol = '☁️  🅰 '
[azure]
symbol = '☁️  ﴃ '
[gcloud]
symbol = '☁️  🇬️ '
EOF

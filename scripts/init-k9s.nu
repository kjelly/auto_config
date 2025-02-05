#!/usr/bin/env nu

let skin_name = "gruvbox-light"
wget $"https://raw.githubusercontent.com/derailed/k9s/refs/heads/master/skins/($skin_name).yaml"
^mv $"($skin_name).yaml" ~/.config/k9s/skins/


open ~/.config/k9s/config.yaml | upsert k9s.ui.skin $skin_name | save -f ~/.config/k9s/config.yaml

let url = (http get "https://api.github.com/repos/derailed/k9s/releases/latest"|get assets |filter {$in.browser_download_url =~ "amd64.deb" } | get browser_download_url|get 0)

wget $url -O /tmp/a.deb
sudo dpkg -i /tmp/a.deb

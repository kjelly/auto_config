#!/usr/bin/env nu

let script_dir = ($env.FILE_PWD? | default ".")
nu ($script_dir | path join "setup-k9s-eink.nu")

let url = (http get "https://api.github.com/repos/derailed/k9s/releases/latest"|get assets |filter {$in.browser_download_url =~ "amd64.deb" } | get browser_download_url|get 0)

wget $url -O /tmp/a.deb
sudo dpkg -i /tmp/a.deb

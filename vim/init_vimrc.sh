#!/usr/bin/env nu

mkdir  ~/.config/nvim/
wget -O ~/.config/nvim/init.lua https://raw.githubusercontent.com/kjelly/auto_config/refs/heads/master/roles/vim/files/init.lua
wget -O ~/.config/nvim/nvim.vim https://raw.githubusercontent.com/kjelly/auto_config/refs/heads/master/roles/vim/files/nvim.vim
mkdir ~/.config/nvim/lsp/
def download-module [] {
  let files = (http get $"https://api.github.com/repos/kjelly/auto_config/roles/vim/files/lsp/")
  cd ~/.config/nvim/lsp/
  $files | par-each -t 2 {|it|
    http get $it.download_url | save -f $it.name
  }
}

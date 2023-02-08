#!/bin/bash
cd ~

curl -fL https://github.com/neovim/neovim/releases/download/nightly/nvim.appimage -o ~/nvim
chmod +x ~/nvim
mkdir -p ~/.config/nvim/bin

go get github.com/arsham/blush
go get -u github.com/xo/usql
go get github.com/miolini/jsonf
go get github.com/htcat/htcat/cmd/htcat
go get github.com/mlimaloureiro/golog
go get github.com/kjelly/jscli
go install github.com/cristianoliveira/ergo

cp `which jq` ~/.config/nvim/bin
cp `which blush` ~/.config/nvim/bin
cp `which usql` ~/.config/nvim/bin
cp `which jsof` ~/.config/nvim/bin
cp `which htcat` ~/.config/nvim/bin
cp `which golog` ~/.config/nvim/bin
cp `which ergo` ~/.config/nvim/bin
cp `which jscli` ~/.config/nvim/bin
cp ~/auto_config/roles/mybin/files/hterm-copy.sh ~/.config/nvim/bin
cp ~/auto_config/roles/mybin/files/hterm-notify.sh ~/.config/nvim/bin

tar zcvf ~/nvim.tar.gz .config/nvim .fzf nvim


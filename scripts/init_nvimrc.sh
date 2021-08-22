export RIPGREP_VERSION=11.0.1
mv ~/.config/nvim/init.vim ~/.config/nvim/init.vim.`date +%F_%R`

curl -fLo ~/.vim/autoload/plug.vim --create-dirs \
    https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim

mkdir -p ~/.config/nvim/autoload/
mkdir -p ~/.config/nvim/bin/

cp ~/.vim/autoload/plug.vim ~/.config/nvim/autoload/plug.vim

curl https://myvimrc.herokuapp.com/vimrc?programming=1 -o ~/.config/nvim/init.vim

mkdir -p ~/.config/nvim/bin

curl -L https://github.com/BurntSushi/ripgrep/releases/download/$RIPGREP_VERSION/ripgrep-$RIPGREP_VERSION-x86_64-unknown-linux-musl.tar.gz -o /tmp/a.tar.gz

tar zxvf /tmp/a.tar.gz -C /tmp

cp /tmp/ripgrep*/rg ~/.config/nvim/bin

git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf

~/.fzf/install --all

touch  ~/.vim_custom.vim

mkdir  ~/.vim/

curl -L https://raw.githubusercontent.com/kjelly/auto_config/master/roles/vim/files/config.lua -o ~/.config/nvim/config.lua
curl -L https://raw.githubusercontent.com/kjelly/auto_config/master/roles/vim/files/clipboard-provider -o ~/.config/nvim/bin/clipboard-provider
chmod +x ~/.config/nvim/bin/clipboard-provider

nvim "+silent! PlugInstall" "+silent! PlugUpdate" +qall

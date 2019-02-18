mv ~/.config/nvim/init.vim ~/.config/nvim/init.vim.`date +%F_%R`

curl -fLo ~/.vim/autoload/plug.vim --create-dirs \
    https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim

mkdir -p ~/.config/nvim/autoload/

cp ~/.vim/autoload/plug.vim ~/.config/nvim/autoload/plug.vim

curl https://myvimrc.herokuapp.com/vimrc?programming=1 -o ~/.config/nvim/init.vim

git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf

~/.fzf/install --all

touch  ~/.vim_custom.vim

# Path to Oh My Fish install.
set -gx OMF_PATH "{{ HOME_PATH }}/.local/share/omf"

# Customize Oh My Fish configuration path.
set -gx OMF_CONFIG "{{ HOME_PATH }}/.config/omf"

# Load oh-my-fish configuration.
source $OMF_PATH/init.fish

alias cd1 "cd .."
alias cd2 "cd ../.."
alias cd3 "cd ../../.."
alias cd4 "cd ../../../.."
alias cd5 "cd ../../../../.."
alias c "vim +Calendar"
alias g "vim +Ag"
alias search "ag .|fzf"
alias enc "openssl enc -aes-256-cbc -a -salt -pass file:$HOME/.ssh/passwd.txt"
alias dec "openssl enc -d -aes-256-cbc -a -salt -pass file:$HOME/.ssh/passwd.txt"
alias nsenter-fzf="nsenter -t (ps aux|fzf|choose 1)"

set fish_color_search_match --background=blue
set -gx GOROOT "{{ HOME_PATH }}/go"
set -gx GOPATH "{{ HOME_PATH }}/gohome"
set -gx GOBIN $GOPATH/bin
set -gx EDITOR nvim
set -gx CDPATH . ~ ~/nfs/
set -gx __fish_git_prompt_showdirtystate 1
set -gx VIM_CONFIG "{{ HOME_PATH }}/.config/nvim/init.vim"
set -gx XDG_RUNTIME_DIR /run/user/(id -u)
if test -z "$FISH_INIT_PATH"
  set -gx PATH {{ FISH_EXTRA_PATH }} $PATH
end
set -gx FISH_INIT_PATH 1

#set -g __fish_vi_mode 1
set -g fish_key_bindings fish_user_key_bindings

if test -z "$VIRTUAL_ENV" ; test -e "$HOME/.asdf/asdf.fish"
  source ~/.asdf/asdf.fish
end

{% if is_wsl.value %}export DISPLAY=127.0.0.1:0.0{% endif %}

if type -q direnv
    direnv hook fish | source
end

function vagrant
  docker run -it --rm \
    -e LIBVIRT_DEFAULT_URI \
    -v /var/run/libvirt/:/var/run/libvirt/ \
    -v ~/.vagrant.d:/.vagrant.d \
    -v (realpath "$PWD"):$PWD \
    -w (realpath "$PWD") \
    --network host \
    vagrantlibvirt/vagrant-libvirt:latest \
      vagrant $argv
end

function vim
  if test -n "$IN_VIM"
    nvr $argv
  else if type -q nvim
    nvim $argv
  else
    vim $argv
  end
end


if test -n "$IN_VIM"
  alias gl="git log --reverse -20"
else
  alias gl="git log"
end

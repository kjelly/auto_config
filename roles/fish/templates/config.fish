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

set -gx GOROOT "{{ HOME_PATH }}/go"
set -gx GOPATH "{{ HOME_PATH }}/gohome"
set -gx PATH "$GOROOT/bin" "{{ HOME_PATH }}/gohome/bin" "{{ HOME_PATH }}/bin" "{{ HOME_PATH }}/mybin" $PATH
set -gx TERM xterm-256color

eval (python -m virtualfish)

#set -g __fish_vi_mode 1
set -g fish_key_bindings fish_user_key_bindings

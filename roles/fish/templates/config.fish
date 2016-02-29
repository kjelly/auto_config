set fisher_home ~/.local/share/fisherman
set fisher_config ~/.config/fisherman
source $fisher_home/config.fish

set -gx PATH "{{ HOME_PATH }}/gohome/bin"  "{{ HOME_PATH }}/bin"  "{{ HOME_PATH }}/mybin" $PATH

alias cd1 "cd .."
alias cd2 "cd ../.."
alias cd3 "cd ../../.."
alias cd4 "cd ../../../.."
alias cd5 "cd ../../../../.."

eval (python -m virtualfish)

set -g fish_key_bindings fish_user_key_bindings

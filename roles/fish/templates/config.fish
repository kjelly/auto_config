set fisher_home ~/.local/share/fisherman
set fisher_config ~/.config/fisherman
source $fisher_home/config.fish


set -gx PATH "{{ HOME_PATH }}/gohome/bin"  "{{ HOME_PATH }}/bin"  "{{ HOME_PATH }}/mybin" $PATH

eval (python -m virtualfish)

set -g fish_key_bindings fish_user_key_bindings

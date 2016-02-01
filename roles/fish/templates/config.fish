# Path to Oh My Fish install.
set -gx OMF_PATH "{{ HOME_PATH }}/.local/share/omf"

# Customize Oh My Fish configuration path.
#set -gx OMF_CONFIG "/home/kjelly/.config/omf"

# Load oh-my-fish configuration.
source $OMF_PATH/init.fish

set -gx PATH  "{{ HOME_PATH }}/bin"  "{{ HOME_PATH }}/mybin" $PATH

eval (python -m virtualfish)

fish_vi_mode

# Path to Oh My Fish install.
set -gx OMF_PATH "{{ HOME_PATH }}/.local/share/omf"

# Customize Oh My Fish configuration path.
#set -gx OMF_CONFIG "/home/kjelly/.config/omf"

# Load oh-my-fish configuration.
source $OMF_PATH/init.fish

eval (python -m virtualfish)

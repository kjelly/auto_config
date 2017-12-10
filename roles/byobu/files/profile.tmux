source $BYOBU_PREFIX/share/byobu/profiles/tmux

# Start windows and panes at 1, not 0
set -g base-index 1
set -g pane-base-index 1
set -g default-terminal "tmux"
set -g default-terminal "screen-256color"
set -g default-shell /usr/local/bin/fish
set -g default-command /usr/local/bin/fish
set -g mouse on


# switch windows alt+number
bind-key -n M-1 select-window -t 1
bind-key -n M-2 select-window -t 2
bind-key -n M-3 select-window -t 3
bind-key -n M-4 select-window -t 4
bind-key -n M-5 select-window -t 5
bind-key -n M-6 select-window -t 6
bind-key -n M-7 select-window -t 7
bind-key -n M-8 select-window -t 8
bind-key -n M-9 select-window -t 9

bind-key -n M-c new-window
bind-key -n M-x confirm-before -p "kill-pane #P? (y/n)" kill-pane

bind-key -n M-[ copy-mode
bind-key -n M-] paste-buffer

bind-key -n M-n next-window
bind-key -n M-p previous-window

bind-key -n M-v split-window -v
bind-key -n M-% split-window -h

bind-key -n M-h  select-pane -L
bind-key -n M-j  select-pane -D
bind-key -n M-k  select-pane -U
bind-key -n M-l  select-pane -R

bind-key -n M-y run-shell "tmux show-buffer | xclip -sel clip -i" \; display-message "Copied tmux buffer to system clipboard"

unbind-key -n C-b
set -g prefix ^B
set -g prefix2 ^B
bind b send-prefix

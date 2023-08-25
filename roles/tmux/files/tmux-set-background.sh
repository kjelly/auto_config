#!/bin/bash

width=$(tmux display -p '#{client_width}')
if [ $width -gt 130 ] && [ $width -le 146 ]; then
    tmux set -g window-style 'fg=#171421,bg=#ffffff'
    tmux set -g status-style 'fg=#171421,bg=#cccccc'
else
    tmux set -g window-style 'fg=#d0cfcc,bg=#171421'
    tmux set -g status-style 'fg=#d0cfcc,bg=#383838'
fi

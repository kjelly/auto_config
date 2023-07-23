#!/bin/bash

width=$(tmux display -p '#{client_width}')

if [ $width -gt 130 ] && [ $width -le 140 ]; then
    tmux set -g window-style 'fg=#171421,bg=#ffffff'
else
    tmux set -g window-style 'fg=#d0cfcc,bg=#171421'
fi

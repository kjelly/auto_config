#!/bin/bash

# Reset global window-style to default so tmux delegates background rendering to each client TTY
tmux set -g window-style default 2>/dev/null
tmux set -g window-active-style default 2>/dev/null

# Maximum width threshold for E-ink display (E-ink is 165-190, Monitor is 220+)
MAX_EINK_WIDTH=200

# Loop through ALL connected tmux clients to independently set each client's TTY background
tmux list-clients -F '#{client_tty} #{client_width} #{session_name}' 2>/dev/null | while read -r c_tty c_width s_name; do
    if [[ -z "$c_tty" ]]; then
        continue
    fi

    lc_eink_val=$(tmux show-environment -t "$s_name" LC_IS_EINK 2>/dev/null | cut -d= -f2)

    is_eink=0
    # Judge by LC_IS_EINK env or client width <= 200
    if [[ "$lc_eink_val" == "1" || "$lc_eink_val" == "true" ]] || \
       [[ -n "$c_width" && "$c_width" -gt 0 && "$c_width" -le "$MAX_EINK_WIDTH" ]]; then
        is_eink=1
    fi

    if [[ $is_eink -eq 1 ]]; then
        # Send OSC 11 (bg #ffffff) and OSC 10 (fg #000000) directly to E-ink client's TTY
        if [[ -w "$c_tty" ]]; then
            printf '\033]11;#ffffff\007\033]10;#000000\007' > "$c_tty" 2>/dev/null
        fi

        if [[ -n "$s_name" ]]; then
            tmux set-option -t "$s_name" status-style 'fg=#000000,bg=#ffffff' 2>/dev/null
            tmux set-option -t "$s_name" window-status-current-style 'fg=#000000,bg=#ffffff,bold,reverse' 2>/dev/null
            tmux set-option -t "$s_name" pane-border-style 'fg=#888888' 2>/dev/null
            tmux set-option -t "$s_name" pane-active-border-style 'fg=#000000,bold' 2>/dev/null
            tmux set-option -t "$s_name" mode-style 'fg=#ffffff,bg=#000000' 2>/dev/null
            tmux set-option -t "$s_name" message-style 'fg=#000000,bg=#ffffff,bold' 2>/dev/null
        fi
    else
        # Send OSC 11 (bg #171421) and OSC 10 (fg #d0cfcc) directly to Monitor client's TTY
        if [[ -w "$c_tty" ]]; then
            printf '\033]11;#171421\007\033]10;#d0cfcc\007' > "$c_tty" 2>/dev/null
        fi

        if [[ -n "$s_name" ]]; then
            tmux set-option -t "$s_name" status-style 'fg=#d0cfcc,bg=#383838' 2>/dev/null
            tmux set-option -t "$s_name" pane-border-style 'fg=#383838' 2>/dev/null
            tmux set-option -t "$s_name" pane-active-border-style 'fg=#d0cfcc,bold' 2>/dev/null
            tmux set-option -t "$s_name" mode-style 'fg=#171421,bg=#d0cfcc' 2>/dev/null
            tmux set-option -t "$s_name" message-style 'fg=#d0cfcc,bg=#383838,bold' 2>/dev/null
        fi
    fi
done

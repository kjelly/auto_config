#!/bin/bash

client_tty=$(tmux display -p '#{client_tty}' 2>/dev/null)
client_name=$(tmux display -p '#{client_name}' 2>/dev/null)
session_name=$(tmux display -p '#{session_name}' 2>/dev/null)
width=$(tmux display -p '#{client_width}' 2>/dev/null)
lc_eink_val=$(tmux show-environment LC_IS_EINK 2>/dev/null | cut -d= -f2)
eink_popup=$((EINK_WIDTH - 2))

# Reset global window-style to default so tmux does not force a single background color on shared windows across different clients
tmux set -g window-style default 2>/dev/null
tmux set -g window-active-style default 2>/dev/null

is_eink=0
if [[ "$lc_eink_val" == "1" || "$lc_eink_val" == "true" ]] || \
   [[ "$session_name" == *-eink ]] || \
   [[ -n "$EINK_WIDTH" && "$width" == "$EINK_WIDTH" ]] || \
   [[ -n "$EINK_WIDTH" && "$width" == "$eink_popup" ]]; then
    is_eink=1
fi

if [[ $is_eink -eq 1 ]]; then
    # Auto-switch E-ink client to -eink session if currently attached to a non-eink session
    if [[ -n "$session_name" && "$session_name" != *-eink ]]; then
        eink_session="${session_name}-eink"
        if ! tmux has-session -t "$eink_session" 2>/dev/null; then
            tmux new-session -d -t "$session_name" -s "$eink_session" 2>/dev/null
        fi
        if [[ -n "$client_name" ]]; then
            tmux switch-client -c "$client_name" -t "$eink_session" 2>/dev/null
            session_name="$eink_session"
        fi
    fi

    # Send OSC 11 (bg) and OSC 10 (fg) directly to THIS client's TTY
    if [[ -n "$client_tty" && -w "$client_tty" ]]; then
        printf '\033]11;#ffffff\007\033]10;#000000\007' > "$client_tty" 2>/dev/null
    fi

    if [[ -n "$session_name" ]]; then
        tmux set-option -t "$session_name" status-style 'fg=#000000,bg=#ffffff' 2>/dev/null
        tmux set-option -t "$session_name" window-status-current-style 'fg=#000000,bg=#ffffff,bold,reverse' 2>/dev/null
        tmux set-option -t "$session_name" pane-border-style 'fg=#888888' 2>/dev/null
        tmux set-option -t "$session_name" pane-active-border-style 'fg=#000000,bold' 2>/dev/null
        tmux set-option -t "$session_name" mode-style 'fg=#ffffff,bg=#000000' 2>/dev/null
        tmux set-option -t "$session_name" message-style 'fg=#000000,bg=#ffffff,bold' 2>/dev/null
        tmux set-environment -t "$session_name" LC_IS_EINK 1 2>/dev/null
        tmux set-environment -t "$session_name" COLORFGBG "15;0" 2>/dev/null
    fi
else
    # Auto-switch Monitor client back to base session if currently attached to an -eink session
    if [[ -n "$session_name" && "$session_name" == *-eink ]]; then
        base_session="${session_name%-eink}"
        if tmux has-session -t "$base_session" 2>/dev/null; then
            if [[ -n "$client_name" ]]; then
                tmux switch-client -c "$client_name" -t "$base_session" 2>/dev/null
                session_name="$base_session"
            fi
        fi
    fi

    # Send OSC 11 (bg) and OSC 10 (fg) for Dark Monitor TTY
    if [[ -n "$client_tty" && -w "$client_tty" ]]; then
        printf '\033]11;#171421\007\033]10;#d0cfcc\007' > "$client_tty" 2>/dev/null
    fi

    if [[ -n "$session_name" ]]; then
        tmux set-option -t "$session_name" status-style 'fg=#d0cfcc,bg=#383838' 2>/dev/null
        tmux set-option -t "$session_name" pane-border-style 'fg=#383838' 2>/dev/null
        tmux set-option -t "$session_name" pane-active-border-style 'fg=#d0cfcc,bold' 2>/dev/null
        tmux set-option -t "$session_name" mode-style 'fg=#171421,bg=#d0cfcc' 2>/dev/null
        tmux set-option -t "$session_name" message-style 'fg=#d0cfcc,bg=#383838,bold' 2>/dev/null
    fi
fi

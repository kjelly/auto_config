#!/usr/bin/env nu

let f = (tmux display-message -p '#{window_id}')
let windows = (tmux list-windows -F "#{pane_current_path}***#{window_id}***#{pane_title}"|lines|each {|it| $it|split column '***' path id title}|flatten|sort-by path title)
$windows|enumerate|each {|it| tmux swap-window -d -s $it.item.id -t $"($it.index + 1)" }
tmux select-window -t $f

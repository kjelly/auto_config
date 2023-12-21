#!/usr/bin/env nu
let f = (tmux display-message -p '#{window_id}')
let windows = (tmux list-windows -F "#{pane_current_path} #{window_id} #{pane_current_command}"|detect columns --no-headers|sort-by column0 column2)
$windows|enumerate|each {|it| tmux move-window -d -s $it.item.column1 -t $"100($it.index + 1)" }
$windows|enumerate|each {|it| tmux move-window -d -s $it.item.column1 -t $"($it.index + 1)"  }
tmux select-window -t $f

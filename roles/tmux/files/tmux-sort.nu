#!/usr/bin/env nu
def has_new_process [ ] {
  let pids = (^ps aux|grep tmux-sort|grep 'nu '|lines|each {|it| $it | split row -r ' +'|get 1|into int})
  $pids|each {|it| $it > $nu.pid}|reduce {|a, b| $a or $b}
}

def main [ ms:duration = 1300ms ] {
  sleep $ms
  if (has_new_process | not $in) {
    let f = (tmux display-message -p '#{window_id}')
    let windows = (tmux list-windows -F "#{pane_current_path}***#{window_id}***#{pane_title}***-#{window_activity}***-#{window_active}"|lines|each {|it| $it|split column '***' path id title active_time active}|flatten|each {|it| $it |upsert active_time ($it.active_time|into int) | upsert active ($it.active | into int) }|sort-by --natural path  active active_time title)
    $windows|enumerate|each {|it| tmux swap-window -d -s $it.item.id -t $"($it.index + 1)" }
    # $windows|enumerate|each {|it| tmux move-window -d -s $it.item.column1 -t $"($it.index + 1)"  }
    tmux select-window -t $f
  }
  null
}


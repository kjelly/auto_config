#!/usr/bin/env nu

def has_new_process [ ] {
  let pids = (^ps aux|grep tmux-sort|grep 'nu '|lines|each {|it| $it | split row -r ' +'|get 1|into int})
  $pids|each {|it| $it > $nu.pid}|reduce {|a, b| $a or $b}
}

def main [ ms:duration = 0ms ] {
  sleep $ms
  if (has_new_process | not $in) {
    let f = (tmux display-message -p '#{window_id}')
    let windows = (tmux list-windows -F "#{pane_current_path}***#{window_id}***#{pane_title}***-#{window_activity}***-#{window_active}***#{pane_current_command}"|lines|each {|it| $it|split column '***' path id title active_time active command}|flatten|each {|it| 
    $it |upsert active_time ($it.active_time|into int) | upsert active ($it.active | into int) | upsert order (
      match $it.command {
        "nvim" => 0
        "vim" => 1
        "k9s" => 3
        "nu" => 97
        "ssh" => 98
        _ => 99
      }
    )}|sort-by --natural path command title)
    $windows|enumerate|each {|it| tmux swap-window -d -s $it.item.id -t $"($it.index + 1)" }
    tmux select-window -t $f
  }
  null
}

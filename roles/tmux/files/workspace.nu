#!/usr/bin/env nu

def main () {
  let path = (zoxide query -l|fzf-tmux |str trim)
  if ($path == "") {
    return
  }
  let lst = (tmux list-windows -F "#{pane_current_path} #{pane_current_command} #{window_id}"|lines|split column ' ' path command winid)
  let target = ($lst|filter {|it| ($it.path == $path ) and ($it.command |str contains "vim") })
  if ($target|is-empty) {
    tmux new-window -b -c ($path) nvim
  } else {
    let winid = ($target|first|get winid)
    tmux select-window -t $"($winid)"
  }
  tmux-sort 100ms
}

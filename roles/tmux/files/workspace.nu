#!/usr/bin/env nu

def main () {
  mut all_path = (zoxide query -l|lines)
  $all_path = ($all_path | append [ '~' ';']|each {|it| [ $it, $"($it)-vim" ] }|flatten)

  mut _path = ($all_path|str join "\n"|fzf-tmux -- --filepath-word|str trim|str replace ';' '~')
  mut _command = "nu"
  if ($_path == "") {
    return
  }
  if ($_path | str contains '-vim') {
      $_path = ($_path|str replace '-vim' '')
      $_command = "nvim"
  }
  let path = ($_path|path expand)
  let command = $_command
  let lst = (tmux list-windows -F "#{pane_current_path} #{pane_current_command} #{window_id}"|lines|split column ' ' path command winid)
  let target = ($lst|filter {|it| ($it.path == $path ) and ($it.command |str contains $command) })
  if ($target|is-empty) {
    tmux new-window -b -c ($path) $command
  } else {
    let winid = ($target|first|get winid)
    tmux select-window -t $"($winid)"
  }
  tmux-sort 100ms
}

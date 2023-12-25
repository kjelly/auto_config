#!/usr/bin/env nu

def parse [ data ] {
    let parts = ($data | split row '@')
    let command = ($parts | last|str trim)
    let path = ($parts | drop | str join '@'|str trim)
    {command: $command, path: $path}
}

def main () {
  mut all_path = (zoxide query -l|lines)
  $all_path = ($all_path | append [ '~' ';']|par-each -t 4 {|it| 
        mut ret = [ $"($it) @ nu", $"($it) @ nvim" ] 
        if ($it|path join kubeconfig|path exists) {
            $ret = ($ret | append [ $"($it) @ k9s " ])
        }
        if ($it|path join nu_workspace_command|path exists) {
            $ret = ($ret | append (open ($it|path join nu_workspace_command)|lines|each {|cmd|
                $"($it) @ ($cmd) "
            }))
        }
        $ret
    }|flatten)

  mut input = ($all_path|str join "\n"|fzf-tmux -- --filepath-word -e +s|str trim|str replace ';' '~')
  if ($input == "") {
    return
  }

  let r = parse $input

  let path = ($r.path|path expand)
  let command = $r.command
  let lst = (tmux list-windows -F "#{pane_current_path} #{pane_current_command} #{window_id}"|lines|split column ' ' path command winid)
  let target = ($lst|filter {|it| ($it.path == $path ) and ($it.command |str contains $command) })
  if ($target|is-empty) {
    tmux new-window -b -c ($path) direnv exec ($path) bash -c $'"($command)"'
  } else {
    let winid = ($target|first|get winid)
    tmux select-window -t $"($winid)"
  }
  tmux-sort 100ms
}

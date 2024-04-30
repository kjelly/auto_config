#!/usr/bin/env nu


def parse [ data ] {
    let data = ($data | str replace '*' '')
    let parts = ($data | split row '@')
    let command = ($parts | last|str trim)
    let path = ($parts | drop | str join '@'|str trim)
    {command: $command, path: $path}
}

def tmux_list_window [ ] {
  tmux list-windows -F "#{pane_current_path} #{pane_current_command} #{window_id}"|lines|split column ' ' path command winid
}

def simple_workspace [ ] {
  mut all_path = (zoxide query -l|lines|first 20)
  let all_windows = (tmux_list_window)
  $all_path = ($all_path | append ( $all_windows | each {|it| $it.path }) | uniq )

  $all_path = ($all_path | append [ '~' ';']|par-each -t 4 {|it| 
        mut ret = [ {path: $it, cmd: "nu"}, {path: $it, cmd: "nvim"}] 

        if ($it|path join kubeconfig|path exists) {
            $ret = ($ret | append [ {path: $it, cmd: "k9s"}])
        }
        if ($it|path join nu_workspace_command|path exists) {
            $ret = ($ret | append (open ($it|path join nu_workspace_command)|lines|each {|cmd|
                $"($it) @ ($cmd)"
                {path: $it, cmd: $cmd}
            }))
        }
        $ret
    }|flatten)

  $all_path = ($all_path | each {|it|
    if ($all_windows | filter {|p| $p.path == $it.path and $p.cmd == $it.cmd} | is-empty) {
      $"($it.path) @ ($it.cmd)"
    } else {
      $"($it.path) @ ($it.cmd)*"
    }
  })

  let tmp = ($all_path|str join "\n")
  let extra  = (tmux list-windows -F "#{pane_current_path} @ #{pane_current_command}*"|lines|filter {|it| ($tmp|str contains $it | not $in) })

  $all_path = ($all_path|append $extra)

  let lst = (tmux list-windows -F "#{pane_current_path} #{pane_current_command} #{window_id}"|lines|split column ' ' path command winid)

  mut input = ($all_path|str join "\n"|fzf-tmux -- --filepath-word --tiebreak=length,end --scheme=path|str trim|str replace ';' '~')
  if ($input == "") {
    return
  }

  let r = parse $input

  let path = ($r.path|path expand)
  let command = $r.command
  let lst = (tmux list-windows -F "#{pane_current_path} #{pane_current_command} #{window_id}"|lines|split column ' ' path command winid)
  let target = ($lst|filter {|it| ($it.path == $path ) and ($it.command |str contains $command) })
  if ($target|is-empty) {
    direnv allow $path
    tmux new-window -b -c ($path) direnv exec ($path) bash -c $'($command)'
  } else {
    let winid = ($target|first|get winid)
    tmux select-window -t $"($winid)"
  }
}

def include [item, lst ] {
  if (($lst | length) == 0) {
    return false
  }
  $lst | each {|it| $item | str contains $it } | reduce {|a, b| $a or $b}
}

def sesh_workspace [ ] {
  let dirs = (zoxide query -l | lines| first 120)
  let dirs = (sesh list | lines| first 120)
  let sessions = (tmux list-sessions -F '#S'|lines | filter {|it| ($it | str length) > 8 })
  let dirs = ($dirs | each {|it| if (include $it $sessions) { $"($it)*" } else { $it } })
  let target = ($dirs | str join "\n" | fzf-tmux | str replace '*' '' | str trim)
  sesh connect $target
}


def main [ ] {
  if (which sesh | is-empty) {
    simple_workspace
  } else {
    # sesh_workspace
    sesh connect (sesh list | fzf-tmux  -p 55%,60% --no-sort --border-label ' sesh ' --prompt '⚡  ' 
                                        --header '  ^a all ^t tmux ^g configs ^x zoxide ^d tmux kill ^f find' 
                                        --bind 'tab:down,btab:up'
                                        --bind 'ctrl-a:change-prompt(⚡  )+reload(sesh list)'
                                        --bind 'ctrl-s:change-prompt(🪟  )+reload(sesh list -t)'
                                        --bind 'ctrl-g:change-prompt(⚙️  )+reload(sesh list -c)'
                                        --bind 'ctrl-x:change-prompt(📁  )+reload(sesh list -z)'
                                        --bind 'ctrl-f:change-prompt(🔎  )+reload(fd -H -d 2 -t d -E .Trash . ~)'
                                        --bind 'ctrl-d:execute(tmux kill-session -t {})+change-prompt(⚡  )+reload(sesh list)'
                                        -- --filepath-word --tiebreak=length,end --scheme=path)
  }
}

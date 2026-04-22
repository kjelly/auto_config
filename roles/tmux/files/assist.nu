#!/usr/bin/env nu

def main [ ] {
  let session_name = (tmux display-message -p '#S')
  if $session_name == "popup" {
    tmux detach-client
    return 0
  }
  let pwd = (tmux display-message -p "#{pane_current_path}")
  let window_args = [ -B -x0 -y0 -w 100% -h 75% ]
  try {
    let pr = (tmux list-windows -F "#{pane_current_path} #{pane_current_command} #{window_id} #{window_index}" -t popup|complete)
    if ($pr.exit_code > 0) {
      tmux display-popup -B -d "#{pane_current_path}" ...$window_args -E $'tmux new-session -e tmux_popup=1 -s popup -c ($pwd) crush'
    } else {
      let windows = $pr.stdout|lines
      let w = ($windows | where $"($pwd) " in $it)
      if ($w | is-empty) {
        tmux display-popup -B -d "#{pane_current_path}" ...$window_args -E $'tmux new-window -e tmux_popup=1 -t popup -c ($pwd) crush'
      } else {
        let win_id = ($w|first|split row ' '|last)
        tmux display-popup -B -d "#{pane_current_path}" ...$window_args -E $'tmux attach -t popup:($win_id)'
      }
    }

  } catch {|err|


  }

}

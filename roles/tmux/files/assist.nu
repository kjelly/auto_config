#!/usr/bin/env nu

def main [ ] {
  let session_name = (tmux display-message -p '#S')
  if $session_name == "popup" {
    tmux detach-client
    return 0
  }
  try {
    let pr = (tmux list-windows -F "#{pane_current_path} #{pane_current_command} #{window_id} #{window_index}" -t popup|complete)
    if ($pr.exit_code > 0) {
      tmux display-popup -d "#{pane_current_path}" -x0 -y0 -w 100% -h 75% -E $'tmux new-session -s popup -c (pwd) crush'
    } else {
      let windows = $pr.stdout|lines
      let w = ($windows | where $"(pwd) " in $it)
      if ($w | is-empty) {
        tmux display-popup -d "#{pane_current_path}" -x0 -y0 -w 100% -h 75% -E $'tmux new-window -t popup -c (pwd) crush'
        # tmux new-window -s popup -c (pwd) crush
      } else {
        let win_id = ($w|first|split row ' '|last)
        # tmux display-popup -d "#{pane_current_path}" -x0 -y0 -w 100% -h 75% -E $'tmux attach-session -t popup:($win_id)'
        tmux display-popup -d "#{pane_current_path}" -x0 -y0 -w 100% -h 75% -E $'tmux attach -t popup:($win_id)'
        # tmux select-window -t $win_id
        # tmux display-popup -d "#{pane_current_path}" -x0 -y0 -w 100% -h 75% -E $'tmux attach-session -t popup  && tmux select-window -t ($win_id)'
      }
    }

  } catch {|err|


  }

}

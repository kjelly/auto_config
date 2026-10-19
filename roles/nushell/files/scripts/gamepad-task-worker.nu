# The pane-died hook runs a fresh, non-interrupted Nu to archive output and close
# the pane. Cleanup must not depend on a Ctrl-C-interrupted worker continuing.
source gamepad.nu

def main [file: path, --finish] {
  if $finish {
    # tmux runs hooks with the server's environment, which may have an older
    # PATH than the calling shell. Restore only PATH for tmux/chmod discovery.
    let snapshot = (open $file)
    $env.PATH = ($snapshot.environment.PATH | split row (char esep))
    menu task-reap (open ($file + '.pane.json')) --finish
    return
  }
  let spec = (open $file)
  # The creator installs ownership and the exit hook before releasing the gate.
  # This also prevents short tasks from exiting before cleanup is registered.
  while not ($file + '.ready' | path exists) { sleep 10ms }
  let terminal = {TMUX: $env.TMUX, TMUX_PANE: $env.TMUX_PANE, TERM: $env.TERM}
  load-env ($spec.environment | reject -o PWD FILE_PWD CURRENT_FILE)
  load-env $terminal
  # UI state belongs to the calling Nu, and exported lists would otherwise be
  # read back as strings by the new Nu's configuration.
  hide-env -i GAMEPAD_TASKS GAMEPAD_DRAFTS GAMEPAD_UNDO _clipboard
  $env.GAMEPAD_TASK_RUNNING = '1'
  cd $spec.cwd
  # Ctrl-C can arrive while the child is still loading config. Do not start the
  # requested command afterwards if cancellation was already requested.
  let command = $"if \(($file + '.stop' | to nuon) | path exists\) { exit 130 }(char newline)($spec.command)"
  let code = (try {
    ^($nu.current-exe) --no-history --config $spec.config --env-config $spec.env_config -c $command
    $env.LAST_EXIT_CODE
  } catch { $env.LAST_EXIT_CODE? | default 1 })
  exit $code
}

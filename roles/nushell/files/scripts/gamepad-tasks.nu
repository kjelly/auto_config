# Task panes are explicitly owned by a random pane option, not merely a pane ID.
# Verify both the server socket and ownership before sending input or closing.
const GAMEPAD_TASK_WORKER = path self gamepad-task-worker.nu
$env.GAMEPAD_TASKS = ($env.GAMEPAD_TASKS? | default [])

def "menu task-call" [task: record, args: list<string>] {
  menu checked tmux (['-S' $task.socket] ++ $args)
}

def "menu task-pane-status" [task: record] {
  let result = (try {
    menu task-call $task [display-message -p -t $task.pane '#{@gamepad_task}|#{pane_dead}|#{pane_dead_status}']
    | str trim | split row '|'
  } catch { [] })
  if (($result | length) != 3) or (($result | first) != $task.token) {
    return {owned: false, running: false, label: '已關閉或不屬於此任務'}
  }
  let running = (($result | get 1) == '0')
  {owned: true, running: $running, exit_code: (try { $result | get 2 | into int } catch { 1 }), label: (if $running { '執行中' } else { $"已結束，狀態 ($result | get 2)" })}
}

def "menu task-result" [task: record] {
  let result = (try { open ($task.file + '.result.json') } catch { null })
  if ($result != null) and ($result.token? == $task.token) { $result } else { null }
}

def "menu task-status" [task: record] {
  let result = (menu task-result $task)
  if $result != null {
    return {owned: true, running: false, label: (if $result.interrupted { '已中止，狀態 130' } else { $"已結束，狀態 ($result.exit_code)" })}
  }
  menu task-pane-status $task | reject -o exit_code
}

def "menu task-reap" [task: record, --finish] {
  # New tasks have a dedicated exit hook. Let that one fresh Nu archive them;
  # foreground menu refreshes must not race the hook's capture/write/close.
  if (not $finish) and ($task.file + '.ready' | path exists) { return }
  let status = (menu task-pane-status $task)
  if (not $status.owned) or $status.running { return }
  if (menu task-result $task) == null {
    let output = (menu task-call $task [capture-pane -p -S '-2000' -t $task.pane])
    let interrupted = ($task.file + '.stop' | path exists)
    let result = {token: $task.token, exit_code: (if $interrupted { 130 } else { $status.exit_code }), interrupted: $interrupted, output: $output}
    let temporary = ($task.file + $".(random uuid).partial")
    $result | to json | save $temporary
    menu checked chmod [600 $temporary] | ignore
    mv --force $temporary ($task.file + '.result.json')
  }
  # Archive first, then recheck ownership before removing this finished pane.
  let current = (menu task-pane-status $task)
  if $current.owned and (not $current.running) {
    menu task-call $task [kill-pane -t $task.pane] | ignore
  }
}

def "menu task-shell-quote" [value: string] {
  "'" + ($value | str replace --all "'" "'\"'\"'") + "'"
}

def "menu task-spawn" [task: record] {
  rm --force --permanent ($task.file + '.ready')
  let created = (if (($env.TMUX? | default '') != '') and (($env.TMUX_PANE? | default '') != '') {
    menu checked tmux [split-window -d -P -F '#{socket_path}|#{pane_id}' -t $env.TMUX_PANE -c $task.cwd $nu.current-exe -n --no-history $GAMEPAD_TASK_WORKER $task.file]
  } else {
    menu checked tmux [new-session -d -P -F '#{socket_path}|#{pane_id}' -s $"gamepad-($task.token)-(random uuid | str substring 0..8)" -c $task.cwd $nu.current-exe -n --no-history $GAMEPAD_TASK_WORKER $task.file]
  } | str trim | split row '|')
  let launched = ($task | upsert socket ($created | get 0) | upsert pane ($created | get 1))
  try {
    $launched | to json | save --force ($task.file + '.pane.json')
    menu checked chmod [600 ($task.file + '.pane.json')] | ignore
    let finish = ([$nu.current-exe '-n' '--no-history' $GAMEPAD_TASK_WORKER '--finish' $task.file]
      | each {|arg| menu task-shell-quote $arg } | str join ' ')
    # tmux parses the hook, then run-shell expands formats and invokes /bin/sh.
    # Quote each layer, and escape # so paths containing #{...} stay literal.
    let hook = ('run-shell -b ' + (menu task-shell-quote $finish) | str replace --all '#' '##')
    menu task-call $launched [
      set-option -p -t $launched.pane @gamepad_task $task.token ';'
      set-option -p -t $launched.pane remain-on-exit on ';'
      set-option -p -t $launched.pane remain-on-exit-format '' ';'
      set-hook -p -t $launched.pane pane-died $hook
    ] | ignore
    # Preserve the previous run's output if creating/configuring a new pane
    # fails. Only discard it when the new worker is ready to be released.
    rm --force --permanent ($task.file + '.stop') ($task.file + '.result.json')
    touch ($task.file + '.ready')
    $launched
  } catch {|err|
    try { menu task-call $launched [kill-pane -t $launched.pane] | ignore }
    error make {msg: $err.msg}
  }
}

def "menu task-find" [token: string] {
  let found = ($env.GAMEPAD_TASKS | where token == $token)
  if ($found | is-empty) { error make {msg: '此工作階段沒有這個任務。'} }
  let task = ($found | first)
  if not (menu task-status $task).owned { error make {msg: '任務 pane 已關閉或所有權不符。'} }
  $task
}

def "menu task-command" [operation: string, token: string] {
  $"menu task-($operation) ($token | to nuon)"
}

def --env "menu task-start" [text: string, --cwd: path] {
  if ($text | str trim | is-empty) { error make {msg: '目前沒有可執行的指令。'} }
  if (which tmux | is-empty) { error make {msg: '任務功能需要 tmux。'} }
  let directory = (mktemp --directory)
  let token = (random uuid)
  let working = ($cwd | default $env.PWD | path expand)
  let file = ($directory | path join 'task.json')
  # Capture the external representation of the environment; never put secret
  # environment values on the tmux command line or in a world-readable file.
  let environment = (^env -0 | complete)
  if $environment.exit_code != 0 { rm -r -p $directory; error make {msg: '無法擷取目前環境。'} }
  let pairs = ($environment.stdout | split row (char nul) | where {|item| $item != '' }
    | parse --regex '^(?<name>[^=]+)=(?<value>[\s\S]*)$')
  let snapshot = ($pairs | transpose --header-row --as-record)
  let spec = {command: $text, cwd: $working, environment: $snapshot, token: $token,
    tmux: (which tmux | first | get path),
    config: ($env.GAMEPAD_TASK_CONFIG? | default $nu.config-path),
    env_config: ($env.GAMEPAD_TASK_ENV_CONFIG? | default $nu.env-path)}
  $spec | to json | save $file
  ^chmod 600 $file
  let task = (try {
    menu task-spawn {token: $token, command: $text, cwd: $working, directory: $directory, file: $file}
  } catch {|err|
    rm --recursive --permanent --force $directory
    error make {msg: $err.msg}
  })
  $env.GAMEPAD_TASKS = ($env.GAMEPAD_TASKS | append $task)
  print $"任務已在 ($task.pane) 啟動；結束後自動關閉 pane，輸出可從任務選單查看。"
}

def "menu task-stop" [token: string] {
  let task = (menu task-find $token)
  if (menu task-status $task).running {
    touch ($task.file + '.stop')
    menu task-call $task [send-keys -t $task.pane C-c] | ignore
    print '已向任務送出 Ctrl-C；可從任務選單重新整理狀態。'
  }
}

def --env "menu task-rerun" [token: string] {
  let task = (menu task-find $token)
  if (menu task-status $task).running { error make {msg: '任務仍在執行；請先中止，結束後再重跑。'} }
  menu task-reap $task
  if (menu task-pane-status $task).owned { error make {msg: '任務 pane 尚未清理完成，請稍後重試。'} }
  let launched = (menu task-spawn $task)
  $env.GAMEPAD_TASKS = ($env.GAMEPAD_TASKS | each {|entry| if $entry.token == $token { $launched } else { $entry } })
}

def --env "menu task-close" [token: string] {
  let task = ($env.GAMEPAD_TASKS | where token == $token | first)
  let status = (menu task-pane-status $task)
  if $status.running { error make {msg: '請先中止任務，結束後再關閉。'} }
  # Explicit removal is also a recovery path if an exit hook could not finish.
  # Only the owned, dead pane may be removed; cached logs never prove ownership
  # of a pane whose numeric ID has subsequently been reused.
  if $status.owned { menu task-call $task [kill-pane -t $task.pane] | ignore }
  rm --recursive --permanent --force $task.directory
  $env.GAMEPAD_TASKS = ($env.GAMEPAD_TASKS | where token != $token)
}

def "menu task-output" [task: record] {
  menu task-reap $task
  let result = (menu task-result $task)
  if $result != null { return $result.output }
  if not (menu task-status $task).owned { error make {msg: '任務 pane 已關閉或所有權不符。'} }
  let output = (try { menu task-call $task [capture-pane -p -S '-2000' -t $task.pane] } catch { null })
  if $output != null { return $output }
  # The exit hook may have archived and closed the pane after the live check.
  let archived = (menu task-result $task)
  if $archived != null { return $archived.output }
  error make {msg: '目前無法讀取任務輸出，請重新整理。'}
}

def --env "menu tasks-menu" [] {
  mut task: any = null
  mut notice = ''
  loop {
    for entry in $env.GAMEPAD_TASKS { menu task-reap $entry }
    if $task == null {
      let items = ([{label: '目前指令在獨立 pane 執行（先預覽）', start: true}]
        | append ($env.GAMEPAD_TASKS | reverse | each {|entry|
          {label: $"[(menu task-status $entry | get label)] ($entry.command)", task: $entry}
        }) | append {label: '↻ 重新整理任務狀態', refresh: true})
      let selected = (menu choose $items $"tmux 任務 · ($notice)")
      if $selected.key in [cancel back] { return $selected }
      if $selected.item.refresh? == true { continue }
      if $selected.item.start? == true {
        if (commandline | str trim | is-empty) { $notice = '請先準備要執行的指令'; continue }
        if (which tmux | is-empty) { $notice = '找不到 tmux'; continue }
        let text = (commandline)
        menu replace $"menu task-start ($text | to nuon) --cwd ($env.PWD | to nuon)"
        return {key: enter}
      }
      $task = $selected.item.task
      continue
    }
    let selected = (menu choose [
      {label: '查看輸出（方向鍵捲動）', action: view}
      {label: '中止任務（送出 Ctrl-C，先預覽）', action: stop}
      {label: '重跑已結束任務（先預覽）', action: rerun}
      {label: '移除已結束任務與保存的輸出（先預覽）', action: close}
    ] $"($task.pane) · (menu task-status $task | get label)(char newline)($task.command)")
    if $selected.key == cancel { return $selected }
    if $selected.key == back { $task = null; continue }
    if $selected.item.action == view {
      loop {
        let output = (menu task-output $task | lines | each {|line| {label: $line} })
        let title = (if (menu has-fzf) { '任務輸出 · Enter 重新整理 · Backspace 返回 · Esc 關閉' } else { '任務輸出 · Enter 重新整理' })
        let chosen = (menu choose ([{label: '↻ 重新整理輸出', refresh: true}] | append $output) $title)
        if $chosen.key == cancel { return $chosen }
        if $chosen.key == back { break }
      }
      continue
    }
    menu replace (menu task-command $selected.item.action $task.token)
    return {key: enter}
  }
}

# Reloading the controller config also migrates owned, finished legacy panes.
for task in $env.GAMEPAD_TASKS { try { menu task-reap $task } }

# Read-only discovery for the controller menu. Every command returned here is
# staged for review by gamepad.nu; discovery never runs a project task.
def "gamepad command" [program: string, args: list<string>] {
  [$"^($program)"] | append ($args | each {|arg| $arg | to nuon }) | str join ' '
}

def "gamepad at" [directory: path, command: string] {
  if $directory == $env.PWD { $command } else { $"cd ($directory | to nuon); ($command)" }
}

def "gamepad git-root" [directory?: path] {
  if (which git | is-not-empty) {
    let result = (^git -C ($directory | default $env.PWD) rev-parse --show-toplevel | complete)
    if $result.exit_code == 0 { return ($result.stdout | str trim -r -c "\n") }
  }
  null
}

def "gamepad project-root" [] {
  let repository = (gamepad git-root)
  if $repository != null { return $repository }
  mut directory = $env.PWD
  loop {
    if ([go.mod nurfile justfile Justfile .justfile Makefile package.json] | any {|name|
      $directory | path join $name | path exists
    }) { return $directory }
    let parent = ($directory | path dirname)
    if $parent == $directory { return $env.PWD }
    $directory = $parent
  }
}

def "gamepad checked" [program: string, args: list<string>] {
  let result = (run-external $program ...$args | complete)
  if $result.exit_code != 0 {
    error make {msg: $"($program): ($result.stderr | str trim)"}
  }
  $result.stdout
}

def "gamepad project-items" [root: path] {
  mut items: list<any> = [{label: '最近的專案執行命令', action: project_recent}]
  if ($root | path join go.mod | path exists) {
    $items ++= ([
      {label: 'Go：執行本專案', args: [run .]}
      {label: 'Go：編譯全部套件', args: [build ./...]}
      {label: 'Go：測試全部套件', args: [test ./...]}
      {label: 'Go：測試資料競爭', args: [test -race ./...]}
    ] | each {|item|
      {label: $item.label, command: (gamepad at $root (gamepad command go $item.args))}
    })
  }
  for task in [
    {files: [nurfile], label: 'nur 任務', action: project_nur}
    {files: [justfile Justfile .justfile], label: 'just 任務', action: project_just}
    {files: [Makefile], label: 'Makefile 任務', action: project_make}
  ] {
    if ($task.files | any {|name| $root | path join $name | path exists }) {
      $items ++= [{label: $task.label, action: $task.action}]
    }
  }
  $items
}

def "gamepad project-recent" [root: path] {
  history --long | gamepad history-items --project $root
  | where command =~ '^\s*\^?(go|nur|just|make|npm|pnpm|yarn|bun|cargo)(\s|$)'
  | each {|row|
    {label: $row.label, command: (gamepad at $row.cwd $row.command)}
  }
}

def "gamepad project-tasks" [root: path, runner: string] {
  let names = (if $runner == just {
    let data = (gamepad checked just [--justfile ($root | path join (
      [justfile Justfile .justfile] | where {|name| $root | path join $name | path exists } | get 0
    )) --no-dotenv --dump --dump-format json] | from json)
    $data.recipes | transpose name data | where {|row| not ($row.data.private? | default false) } | get name
  } else if $runner == nur {
    # Some nur versions have no --nurfile flag. Discover from the project root,
    # just as the staged task will run, without changing the caller's directory.
    do { cd $root; gamepad checked nur [--list --quiet] }
    | lines | where {|name| $name | str trim | is-not-empty }
  } else {
    open --raw ($root | path join Makefile) | lines
    | parse --regex '^(?<name>[A-Za-z0-9][A-Za-z0-9_.-]*)\s*:(?:[^=]|$)'
    | get name | uniq
  })
  $names | each {|name|
    {label: $name, command: (gamepad at $root (gamepad command $runner [$name]))}
  }
}

def "gamepad file-entries" [directory: path] {
  [{label: '.. 上一層', path: ($directory | path dirname), kind: directory}]
  | append (
    ls --all $directory | where {|entry| $entry.name | path type | $in in [dir file] }
    | sort-by type name | each {|entry|
      let is_dir = (($entry.name | path type) == dir)
      {label: $"(if $is_dir { '📁 ' } else { '' })($entry.name | path basename)", path: $entry.name, kind: (if $is_dir { 'directory' } else { 'file' })}
    }
  )
}

def "gamepad project-files" [root: path] {
  let paths = (if ($root | path join .git | path exists) {
    gamepad checked git [-C $root ls-files --cached --others --exclude-standard -z]
    | split row (char nul) | where {|name| $name != '' } | uniq
    | each {|name| $root | path join $name }
  } else {
    # Keep glob metacharacters in the project directory literal.
    do { cd $root; glob '**/*' --no-dir --exclude ['**/.git/**' '**/node_modules/**' '**/target/**' '**/vendor/**'] }
  })
  $paths | where {|name| ($name | path type) == file } | sort
  | each {|name|
    {label: ($name | path relative-to $root), command: (gamepad command nvim [-- $name])}
  }
}

def "gamepad git-items" [root: path] {
  # Check the repository now, rather than showing commands that will all fail.
  gamepad checked git [-C $root rev-parse --git-dir] | ignore
  [
    {label: '狀態與目前分支', args: [status --short --branch]}
    {label: '尚未暫存的差異', args: [diff --]}
    {label: '已暫存的差異', args: [diff --cached --]}
    {label: '最近 30 筆提交', args: [log --oneline --decorate '-30']}
    {label: '列出本機分支', args: [branch --list]}
  ] | each {|item|
    {label: $item.label, command: (gamepad command git ([--no-pager -C $root] ++ $item.args))}
  } | append [
    {label: '選擇變更檔案，用 nvim 開啟', action: git_files}
    {label: '選擇分支切換', action: git_branches}
  ]
}

def "gamepad git-files" [root: path] {
  let fields = (gamepad checked git [-C $root status --porcelain=v1 -z --untracked-files=all] | split row (char nul))
  mut files = []
  mut skip = false
  for field in $fields {
    if $skip { $skip = false; continue }
    if $field == '' { continue }
    let status = ($field | str substring 0..1)
    let name = ($field | str substring 3..)
    let path = ($root | path join $name)
    if ($path | path type) == file {
      $files ++= [{label: $"($status) ($name)", command: (gamepad command nvim [-- $path])}]
    }
    # In -z format renames/copies have destination first, then a second NUL field.
    $skip = ($status =~ '[RC]')
  }
  $files
}

def "gamepad git-branches" [root: path] {
  gamepad checked git [-C $root for-each-ref '--format=%(refname:short)' refs/heads]
  | lines | each {|name|
    {label: $name, command: (gamepad command git [-C $root switch -- $name])}
  }
}

def "gamepad tmux-items" [] {
  let result = (^tmux list-panes -a -F "#{session_id}\t#{window_id}\t#{pane_id}\t#{session_name}:#{window_index}.#{pane_index} #{pane_current_command}" | complete)
  let inside = ($env.TMUX? | default '' | is-not-empty)
  let panes = (if $result.exit_code == 0 {
    $result.stdout | lines
    | parse --regex '^(?<session>\$[0-9]+)\t(?<window>@[0-9]+)\t(?<pane>%[0-9]+)\t(?<label>.*)$'
    | each {|pane|
      let select = (if $inside { 'switch-client' } else { 'attach-session' })
      {label: $pane.label, command: (gamepad command tmux [
        $select -t $pane.session ';' select-window -t $pane.window ';' select-pane -t $pane.pane
      ])}
    }
  } else { [] })
  $panes | append {
    label: (if $inside { '＋ 在目前目錄開新視窗' } else { '＋ 在目前目錄建立工作區' })
    command: (gamepad command tmux [(if $inside { 'new-window' } else { 'new-session' }) -c $env.PWD])
  }
}

def "gamepad parent" [action: string] {
  match $action {
    remove_favorite => { 'manage' }
    frequent => { 'directories' }
    project_recent | project_nur | project_just | project_make => { 'project' }
    files_browser | files_project => { 'files' }
    git_files | git_branches => { 'git' }
    _ => { 'main' }
  }
}

# Controller workflow for Nushell 0.116+: Esc -> menu -> choose -> review -> Enter.
# Favorites live beside config.nu. Override GAMEPAD_FAVORITES_FILE for another file.
# All interactive gamepad menus use fzf for consistent Backspace navigation.
# Selecting a command only stages it for review.
$env.GAMEPAD_FAVORITES_FILE = ($env.GAMEPAD_FAVORITES_FILE? | default (
  $nu.default-config-dir | path join 'gamepad-favorites.nuon'
))
$env.GAMEPAD_UNDO = ($env.GAMEPAD_UNDO? | default [])

def "gamepad favorites" [] {
  if not ($env.GAMEPAD_FAVORITES_FILE | path exists) { return [] }
  let favorites = (open $env.GAMEPAD_FAVORITES_FILE)
  if ($favorites | describe) !~ '^list|^table' {
    error make {msg: '手把收藏必須是含 label、command 的列表。'}
  }
  $favorites | each {|entry|
    if (($entry.label? | describe) != string) or (($entry.command? | describe) != string) {
      error make {msg: '每筆手把收藏都需要字串 label 與 command。'}
    }
    $entry | select label command
  }
}

# Select by original index so display sanitization never changes stored values.
# 不使用內建 input list --fuzzy：它沒有自訂按鍵／返回事件的介面，
# 無法做到「有搜尋文字時 Backspace 刪字，空白時返回上一層」。
# fzf 的 backward-eof 事件可區分這兩種情況，並保留歷史切換所需的查詢文字。
def "gamepad pick" [items: list<record>, title: string, --browse, --fuzzy, --history-controls, --query: string = ''] {
  if ($items | is-empty) and (not $fuzzy) { return {key: back} }
  if (which fzf | is-empty) {
    error make {msg: '手把選單需要 fzf；請確認 fzf 在 PATH 中。'}
  }
  let rows = ($items | enumerate | each {|row|
    let label = ($row.item.label | ansi strip | str replace --all --regex '[\x00-\x1f\x7f]' ' ')
    $"($row.index)(char tab)($label)"
  } | str join (char newline))
  # print(key)+accept returns the event even with no matches (exit status 1).
  # Do not use --expect=backspace: it would intercept the key before deletion.
  let navigation = (if $history_controls {
    'left:print(left)+accept,right:print(right)+accept,tab:print(tab)+accept'
  } else if $browse {
    'tab:down,space:print(enter)+accept,left:print(left)+accept,right:print(right)+accept'
  } else if $fuzzy {
    'tab:down'
  } else {
    'tab:down,space:print(enter)+accept,left:page-up,right:page-down'
  })
  let back = (if $fuzzy {
    'backspace:backward-delete-char,backward-eof:print(backspace)+accept'
  } else { 'backspace:print(backspace)+accept' })
  let bindings = (['enter:print(enter)+accept' $navigation $back] | str join ',')
  let search_options = (if $fuzzy {
    ['--scheme=history' '--query' $query]
  } else { ['--no-input' '--disabled' '--no-sort'] })
  let result = (with-env {FZF_DEFAULT_OPTS: '', FZF_DEFAULT_OPTS_FILE: ''} {
    $rows | (^fzf ...$search_options --layout=reverse --height='~14' --cycle
      --delimiter "\t" --with-nth=2.. --bind $bindings --print-query
      --header $title) | complete
  })
  let output = ($result.stdout | lines)
  let key = ($output | get -o 1 | default '')
  if $key == backspace { return {key: back} }
  # fzf exits with status 1 when scope changes with no matches. Keep the query
  # and honor the key even when there is no selected row (or no local history).
  if $history_controls and ($key in [left right tab]) {
    return {key: $key, query: ($output | get 0)}
  }
  if $result.exit_code in [1 130] { return {key: cancel} }
  if $result.exit_code != 0 { error make {msg: $"fzf: ($result.stderr | str trim)"} }
  let index = ($output | get 2 | split row (char tab) | get 0 | into int)
  {key: $key, item: ($items | get $index), index: $index}
}

def --env "gamepad remember" [] {
  $env.GAMEPAD_UNDO = ($env.GAMEPAD_UNDO | append {
    buffer: (commandline), cursor: (commandline get-cursor)
  } | last 20)
}

def --env "gamepad replace" [text: string] {
  gamepad remember
  commandline edit --replace $text
  commandline set-cursor --end
}

def --env "gamepad insert" [text: string] {
  gamepad remember
  commandline edit --insert $text
}

# Like Ctrl-O, edit a temporary copy and stage the result for review. nvim's
# final file newline is not part of the command; preserve any other newlines.
def --env "gamepad edit" [] {
  let file = (mktemp --suffix .nu)
  try {
    commandline | save --force --raw $file
    ^nvim $file
    if $env.LAST_EXIT_CODE == 0 {
      gamepad replace (open --raw $file | str replace --regex '\r?\n\z' '')
    }
  } catch {|err|
    rm --permanent --force $file
    error make $err
  }
  rm --permanent --force $file
}

# Reverse before deduplication so the most recent spelling/order wins.
# --long supplies cwd/exit_status for SQLite history; keep multiline commands intact.
def "gamepad history" [--here, --status: string = 'all'] {
  history --long | gamepad history-items --here=$here --status $status
}

def "gamepad history-items" [--here, --status: string = 'all', --project: path] {
  let rows = $in
  let current = $env.PWD
  $rows | reverse
  | where {|row|
    let directory = ($row.cwd? | default '')
    let code = $row.exit_status?
    ((($row.command | str trim) != '')
      and (match $status { success => { $code == 0 }, failed => { ($code != null) and ($code != 0) }, _ => { true } })
      and ((not $here) or ($directory == $current))
      and (($project == null) or ($directory == $project) or ($directory | str starts-with $"($project | default '' | str trim -r -c '/')/")))
  }
  | uniq-by command
  | each {|row|
    let code = ($row.exit_status? | default '?')
    {label: $"[($code)] ($row.command)", command: $row.command, cwd: $row.cwd?}
  }
}

# Match literal text, including incomplete quotes, without evaluating history.
# Cursor indexes are Unicode characters; substring indexes are UTF-8 bytes.
def "gamepad snippet-items" [buffer: string, cursor: int] {
  let rows = $in
  if $cursor <= 0 { return [] }
  let characters = ($buffer | split chars)
  let prefix = ($characters | take $cursor | str join '' | str trim --left)
  if ($prefix | str trim | is-empty) { return [] }
  let right = ($characters | skip $cursor | str join '')
  let prefix_bytes = ($prefix | str length)
  let current = $env.PWD
  let candidates = ($rows | reverse
    | where {|row| $row.command | str trim --left | str starts-with $prefix }
    | each {|row|
      let tail = ($row.command | str trim --left | str substring $prefix_bytes..)
      # A bare 'git' must not match 'github'. Partial arguments ('git lo') do.
      if ($prefix !~ '\s') and ($tail !~ '^\s') { return null }
      let snippet = (if ($right != '') and ($tail | str ends-with $right) {
        $tail | str substring 0..<(($tail | str length) - ($right | str length))
      } else { $tail })
      if ($snippet | str trim | is-empty) { return null }
      let here = ($row.cwd? == $current)
      let scope = (if $here { '目前目錄' } else { '全域' })
      {label: $"[($scope)] ($snippet)", snippet: $snippet, here: $here}
    } | compact)
  # Preserve recency within each scope, and keep the local copy of duplicates.
  ($candidates | where here) | append ($candidates | where here == false)
  | uniq-by snippet
}

def "gamepad snippets" [] {
  history --long | gamepad snippet-items (commandline) (commandline get-cursor)
}

source gamepad-tools.nu

# Browsing does not change PWD or run hooks. Only 'use this directory' stages cd.
# to nuon quotes paths as Nu literals, including spaces, quotes and interpolation.
def "gamepad directories" [directory: path] {
  let directory = ($directory | path expand)
  let parent = ($directory | path dirname)
  [
    {label: '✓ 使用此目錄', path: $directory, kind: use}
    {label: '.. 上一層', path: $parent, kind: directory}
    {label: '~ 家目錄', path: $env.HOME, kind: directory}
    {label: '常用目錄（zoxide）', path: $directory, kind: frequent}
  ] | append (
    ls --all $directory | where {|entry| $entry.name | path type | $in == dir }
    | sort-by name | each {|entry|
      {label: ($entry.name | path basename), path: $entry.name, kind: directory}
    }
  )
}

def "gamepad frequent directories" [] {
  if (which zoxide | is-empty) { return [] }
  let result = (^zoxide query --list | complete)
  if $result.exit_code != 0 { return [] }
  $result.stdout | lines | where {|dir| $dir | path type | $in == dir }
  | each {|dir| {label: $dir, path: $dir} }
}

def --env "gamepad run" [initial_action: string] {
  # Hand the terminal to fzf without leaving Reedline hints or menu rows behind.
  print --no-newline (ansi clear_screen_from_cursor_to_end)
  mut action = $initial_action
  mut directory = $env.PWD
  mut notice = ''
  mut history_query = ''
  mut history_status = 'all'
  mut root = ''
  loop {
    if $action == main {
      let selected = (gamepad pick (gamepad actions) $"($notice)手把：↑↓ / Tab 選擇 · Enter 確認 · Backspace / Esc 關閉")
      if $selected.key in [cancel back] { return }
      $action = $selected.item.action
      $notice = ''
      continue
    }
    if $action == clear {
      gamepad replace ''
      return
    }
    if $action == edit {
      gamepad edit
      return
    }
    if $action == undo {
      if ($env.GAMEPAD_UNDO | is-not-empty) {
        let previous = ($env.GAMEPAD_UNDO | last)
        $env.GAMEPAD_UNDO = ($env.GAMEPAD_UNDO | drop 1)
        commandline edit --replace $previous.buffer
        commandline set-cursor $previous.cursor
      }
      return
    }
    if $action == add_favorite {
      let command = (commandline)
      if ($command | str trim | is-not-empty) {
        let favorites = (gamepad favorites)
        if not ($favorites | any {|item| $item.command == $command }) {
          $favorites | append {label: $command, command: $command}
          | save --force $env.GAMEPAD_FAVORITES_FILE
        }
      }
      return
    }
    if $action =~ '^git' {
      let repository = (gamepad git-root)
      if $repository == null {
        $notice = $"目前目錄不是 Git 專案，請先用「瀏覽目錄」切換到專案。(char newline)"
        $action = 'main'
        continue
      }
      $root = $repository
    } else if ($root == '') and ($action =~ '^(project|files)') {
      $root = (gamepad project-root)
    }
    let items = (match $action {
      manage => { gamepad management }
      favorites | remove_favorite => { gamepad favorites }
      history_here => { gamepad history --here --status $history_status }
      history_all => { gamepad history --status $history_status }
      snippets => { gamepad snippets }
      directories => { gamepad directories $directory }
      frequent => { gamepad frequent directories }
      project => { gamepad project-items $root }
      project_recent => { gamepad project-recent $root }
      project_nur => { gamepad project-tasks $root nur }
      project_just => { gamepad project-tasks $root just }
      project_make => { gamepad project-tasks $root make }
      files => { [
        {label: '瀏覽目前目錄與子目錄', action: files_browser}
        {label: '搜尋專案檔案（含未追蹤檔案）', action: files_project}
      ] }
      files_browser => { gamepad file-entries $directory }
      files_project => { gamepad project-files $root }
      git => { gamepad git-items $root }
      git_files => { gamepad git-files $root }
      git_branches => { gamepad git-branches $root }
      tmux => { gamepad tmux-items }
    })
    let is_history = ($action in [history_here history_all])
    if ($items | is-empty) and (not $is_history) {
      $notice = (if $action == snippets {
        $"找不到可接續的歷史片段；請先輸入曾使用的指令前綴。(char newline)"
      } else { $"沒有可用項目，請選擇其他功能。(char newline)" })
      $action = (gamepad parent $action)
      continue
    }
    let fuzzy = ($is_history or ($action in [snippets files_project git_files git_branches project_recent tmux]))
    let context = (if $action == snippets {
      $"插入歷史片段：依游標前文字比對 · 目前目錄優先(char newline)"
    } else if $action =~ '^(project|git|files_project)' { $"專案：($root)(char newline)" } else { '' })
    let title = (if $action in [directories files_browser] {
      $"($directory)(char newline)← / Backspace 上一層 · → / Enter 進入 · Esc 關閉"
    } else if $is_history {
      let scope = (if $action == history_here { '目前目錄' } else { '全域' })
      let status = (match $history_status { success => { '成功' }, failed => { '失敗或中斷' }, _ => { '全部' } })
      $"歷史：($scope) / ($status) · ← 目前目錄 / → 全域 · Tab 切換狀態(char newline)輸入文字模糊搜尋 · ↑↓ 選擇 · Enter 確認 · Backspace 刪字／空白返回 · Esc 關閉"
    } else if $fuzzy {
      $"($context)($notice)輸入文字搜尋 · ↑↓ / Tab 選擇 · Enter 確認 · Backspace 刪字／空白返回 · Esc 關閉"
    } else {
      $"($context)($notice)↑↓ / Tab 選擇 · Enter 確認 · Backspace 返回上一層 · Esc 關閉"
    })
    let selected = (gamepad pick $items $title --browse=($action in [directories files_browser]) --fuzzy=$fuzzy --history-controls=$is_history --query (if $is_history { $history_query } else { '' }))
    if $selected.key == cancel { return }
    $notice = ''
    if $is_history and ($selected.key in [left right tab]) {
      $history_query = $selected.query
      if $selected.key == tab {
        $history_status = (match $history_status { all => { 'success' }, success => { 'failed' }, _ => { 'all' } })
      } else {
        $action = (if $selected.key == left { 'history_here' } else { 'history_all' })
      }
      continue
    }
    if $selected.key == back {
      if $is_history { $history_query = '' }
      if ($action in [directories files_browser]) and ($directory != ($directory | path dirname)) {
        $directory = ($directory | path dirname)
      } else { $action = (gamepad parent $action) }
      continue
    }
    if $selected.item.action? != null {
      $action = $selected.item.action
      continue
    }
    if $action in [directories files_browser] {
      if $selected.key == left {
        $directory = ($directory | path dirname)
      } else if $selected.item.kind == frequent {
        $action = 'frequent'
      } else if $selected.item.kind == use {
        gamepad replace $"cd ($directory | to nuon)"
        return
      } else if $selected.item.kind == file {
        gamepad replace (gamepad command nvim [-- $selected.item.path])
        return
      } else {
        $directory = $selected.item.path
      }
      continue
    }
    if $action == frequent {
      $directory = $selected.item.path
      $action = 'directories'
      continue
    }
    if $action == remove_favorite {
      $items | drop nth $selected.index | save --force $env.GAMEPAD_FAVORITES_FILE
      $action = 'manage'
      continue
    }
    if $action == snippets {
      gamepad insert $selected.item.snippet
      return
    }
    gamepad replace $selected.item.command
    return
  }
}

def "gamepad actions" [] {
  [
    {label: '收藏命令', action: favorites}
    {label: '歷史搜尋（預設目前目錄，→ 全域）', action: history_here}
    {label: '依目前指令插入歷史片段（Snippet）', action: snippets}
    {label: '本專案操作', action: project}
    {label: '選檔案，用 nvim 開啟', action: files}
    {label: 'Git 工具', action: git}
    {label: 'tmux 工作區切換', action: tmux}
    {label: '瀏覽目錄', action: directories}
    {label: '用 nvim 編輯命令列（Ctrl-O）', action: edit}
    {label: '管理收藏與命令列', action: manage}
  ]
}

def "gamepad management" [] {
  [
    {label: '收藏目前命令', action: add_favorite}
    {label: '移除收藏', action: remove_favorite}
    {label: '清空命令列', action: clear}
    {label: '復原手把變更', action: undo}
  ]
}

# Remove the previous Reedline launcher when re-sourcing this file.
$env.config.menus = ($env.config.menus | where name != gamepad_menu)

# Keep menus compact, and give menu navigation priority over history hints.
$env.config.menus = ($env.config.menus | each {|menu|
  if $menu.name == ide_completion_menu {
    $menu | update type ($menu.type | merge {
      max_completion_width: 60, max_completion_height: 10
      max_description_width: 60, max_description_height: 10
      description_mode: prefer_right
    })
  } else { $menu }
})
$env.config.keybindings = ($env.config.keybindings | where {|binding| $binding.name !~ '^gamepad_' } | append [
  {
    name: gamepad_menu, modifier: none, keycode: esc, mode: [emacs]
    # MenuUp only applies to an open completion menu. Close that menu before
    # repainting; otherwise ExecuteHostCommand opens fzf and ends this event chain.
    event: [
      {until: [{send: menuup}, {send: executehostcommand, cmd: 'gamepad run main'}]}
      {send: esc}
    ]
  }
  {
    name: gamepad_accept, modifier: none, keycode: enter, mode: [emacs]
    # Accept a completion without submitting it; normal Enter submits the line.
    event: {until: [{send: menuaccept}, {send: enter}]}
  }
  {
    name: gamepad_left, modifier: none, keycode: left, mode: [emacs]
    event: {until: [{send: menupageprevious}, {send: menuleft}, {send: left}]}
  }
  {
    name: gamepad_right, modifier: none, keycode: right, mode: [emacs]
    event: {until: [{send: menupagenext}, {send: menuright}, {send: historyhintcomplete}, {send: right}]}
  }
])

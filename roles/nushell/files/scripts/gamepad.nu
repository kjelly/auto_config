source history-query.nu
# Keep file names, storage keys and tmux ownership markers stable across renames.
const GAMEPAD_EDIT_WORKER = path self gamepad-edit.nu

# 開啟命令選單，供鍵盤與手把使用；選取後檢查命令，再按 Enter 執行。
def --env menu [] {
  menu run main
}

# 互動搜尋歷史指令，預設只搜尋目前目錄。
def --env "menu history" [
  --global # 搜尋所有目錄的歷史紀錄。
] {
  menu run (if $global { 'history_all' } else { 'history_here' })
}

# Controller workflow for Nushell 0.116+: Esc -> menu -> choose -> review -> Enter.
# Favorites live beside config.nu. Override GAMEPAD_FAVORITES_FILE for another file.
# All interactive controller menus use fzf for consistent Backspace navigation.
# Selecting a command only stages it for review.
$env.GAMEPAD_FAVORITES_FILE = ($env.GAMEPAD_FAVORITES_FILE? | default (
  $nu.default-config-dir | path join 'gamepad-favorites.nuon'
))
$env.GAMEPAD_UNDO = ($env.GAMEPAD_UNDO? | default [])

def "menu favorites" [] {
  if not ($env.GAMEPAD_FAVORITES_FILE | path exists) { return [] }
  let favorites = (open $env.GAMEPAD_FAVORITES_FILE)
  if ($favorites | describe) !~ '^list|^table' {
    error make {msg: '選單收藏必須是含 label、command 的列表。'}
  }
  $favorites | each {|entry|
    if (($entry.label? | describe) != string) or (($entry.command? | describe) != string) {
      error make {msg: '每筆選單收藏都需要字串 label 與 command。'}
    }
    let parameters = ($entry.parameters? | default [])
    if ($parameters | describe) !~ '^list|^table' {
      error make {msg: '收藏 parameters 必須是欄位列表。'}
    }
    if ($parameters | is-empty) { $entry | select label command } else {
      $entry | select label command parameters
    }
  }
}

# Select by original index so display sanitization never changes stored values.
# 不使用內建 input list --fuzzy：它沒有自訂按鍵／返回事件的介面，
# 無法做到「有搜尋文字時 Backspace 刪字，空白時返回上一層」。
# fzf 的 backward-eof 事件可區分這兩種情況，並保留歷史切換所需的查詢文字。
def "menu pick" [items: list<record>, title: string, --browse, --fuzzy, --history-controls, --path-controls, --file-controls, --query: string = '', --editor-state: path] {
  if ($items | is-empty) and (not $fuzzy) and (not $history_controls) and (not $file_controls) { return {key: back} }
  if (which fzf | is-empty) {
    error make {msg: '命令選單需要 fzf；請確認 fzf 在 PATH 中。'}
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
  # Search menus keep Home/End editing the query, even when it is empty.
  # Plain menus have no input field, so Home/End navigate the result list.
  let endpoints = (if $fuzzy {
    'home:beginning-of-line,end:end-of-line'
  } else { 'home:first,end:last' })
  let bindings = ([
    'enter:print(enter)+accept,shift-tab:up,page-up:page-up,page-down:page-down'
    $navigation $back $endpoints
    (if $file_controls { 'tab:print(tab)+accept' } else { '' })
    (if $path_controls { 'space:print(toggle)+accept' } else { '' })
    (if $editor_state != null {
      # Keep one fzf process alive. Commands contain only fixed shell syntax;
      # paths travel via environment variables and {1} is the numeric row index.
      let apply = '"$GAMEPAD_EDIT_NU" -n --no-history "$GAMEPAD_EDIT_WORKER" apply "$GAMEPAD_EDIT_STATE" {1}'
      let header = '"$GAMEPAD_EDIT_NU" -n --no-history "$GAMEPAD_EDIT_WORKER" header "$GAMEPAD_EDIT_STATE"'
      let control = 'if [ -e "$GAMEPAD_EDIT_STATE.close" ]; then printf %s "print(enter)+accept"; else printf %s ignore; fi'
      let operation = $"transform-header\(($apply)\)+transform~($control)~"
      $"enter:($operation),space:($operation),resize:transform-header\(($header)\)"
    } else { '' })
  ] | where {|binding| $binding != '' } | str join ',')
  let search_options = (if $fuzzy {
    ['--scheme=history' '--query' $query]
  } else { ['--no-input' '--disabled' '--no-sort'] })
  let editor_options = (if $editor_state != null { ['--with-shell' 'sh -c'] } else { [] })
  let result = (with-env {FZF_DEFAULT_OPTS: '', FZF_DEFAULT_OPTS_FILE: '', GAMEPAD_EDIT_NU: $nu.current-exe, GAMEPAD_EDIT_WORKER: $GAMEPAD_EDIT_WORKER, GAMEPAD_EDIT_STATE: ($editor_state | default '')} {
    $rows | (^fzf ...$search_options ...$editor_options --layout=reverse --height='~14' --cycle
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
  # Mode switches must work with an empty project or a query with no matches.
  # Return before decoding a selected row, which may not exist in either case.
  if $file_controls and ($key == tab) {
    return {key: tab, query: ($output | get 0)}
  }
  if $result.exit_code in [1 130] { return {key: cancel} }
  if $result.exit_code != 0 { error make {msg: $"fzf: ($result.stderr | str trim)"} }
  let index = ($output | get 2 | split row (char tab) | get 0 | into int)
  let selected = {key: $key, item: ($items | get $index), index: $index}
  if $file_controls { $selected | insert query ($output | get 0) } else { $selected }
}

def --env "menu remember" [] {
  $env.GAMEPAD_UNDO = ($env.GAMEPAD_UNDO | append {
    buffer: (commandline), cursor: (commandline get-cursor)
  } | last 20)
}

def --env "menu replace" [text: string] {
  menu remember
  commandline edit --replace $text
  commandline set-cursor --end
}

def --env "menu insert" [text: string] {
  menu remember
  commandline edit --insert $text
}

# Nushell cursor positions count grapheme clusters (visible characters), not
# Unicode code points or UTF-8 bytes. Keep combined accents and emoji intact.
# Line operations respect explicit newlines rather than terminal wrapping.
def "menu line-edit" [buffer: string, cursor: int, action: string] {
  let characters = ($buffer | split chars --grapheme-clusters)
  let left = ($characters | take $cursor | str join '')
  let right = ($characters | skip $cursor | str join '')
  match $action {
    line_start => {
      let offset = ($left | split row (char newline) | last | split chars --grapheme-clusters | length)
      {buffer: $buffer, cursor: ($cursor - $offset)}
    }
    line_end => {
      let offset = ($right | split row (char newline) | first | split chars --grapheme-clusters | length)
      {buffer: $buffer, cursor: ($cursor + $offset)}
    }
    previous_char => {
      let offset = ($left | split chars --grapheme-clusters | last | default '' | str length --grapheme-clusters)
      {buffer: $buffer, cursor: ($cursor - $offset)}
    }
    next_char => {
      let offset = ($right | split chars --grapheme-clusters | first | default '' | str length --grapheme-clusters)
      {buffer: $buffer, cursor: ($cursor + $offset)}
    }
    previous_word => {
      let remaining = ($left | str replace --regex '\S+\s*$|\s+$' '')
      {buffer: $buffer, cursor: ($remaining | str length --grapheme-clusters)}
    }
    next_word => {
      let remaining = ($right | str replace --regex '^\s*\S+|^\s+' '')
      {buffer: $buffer, cursor: (($buffer | str length --grapheme-clusters) - ($remaining | str length --grapheme-clusters))}
    }
    delete_previous_char => {
      let count = ($left | split chars --grapheme-clusters | drop 1 | str join '' | str length --grapheme-clusters)
      let remaining = ($characters | take $count | str join '')
      {buffer: ($remaining + $right), cursor: $count}
    }
    delete_next_char => {
      let remaining = ($right | split chars --grapheme-clusters | skip 1 | str join '')
      {buffer: ($left + $remaining), cursor: $cursor}
    }
    delete_next_word => {
      let remaining = ($right | str replace --regex '^\s*\S+|^\s+' '')
      {buffer: ($left + $remaining), cursor: $cursor}
    }
    delete_word => {
      # Whitespace-delimited words keep flags and paths together. Also remove
      # trailing whitespace, matching the usual shell "delete previous word".
      let remaining = ($left | str replace --regex '\S+\s*$|\s+$' '')
      {buffer: ($remaining + $right), cursor: ($remaining | split chars --grapheme-clusters | length)}
    }
    _ => { error make {msg: $"Unknown command-line edit: ($action)"} }
  }
}

def --env "menu edit-line" [action: string] {
  let original = {buffer: (commandline), cursor: (commandline get-cursor)}
  let edited = (menu line-edit $original.buffer $original.cursor $action)
  if $edited != $original {
    menu remember
    if $edited.buffer != $original.buffer { commandline edit --replace $edited.buffer }
    commandline set-cursor $edited.cursor
  }
}

def "menu edit-actions" [] {
  [line_start line_end delete_word previous_char next_char previous_word next_word
   delete_next_word delete_previous_char delete_next_char]
}

# Show a bounded window around the cursor. Preview text is never evaluated;
# stripping terminal controls prevents history text from changing the display.
def "menu edit-preview" [buffer: string, cursor: int, columns: int] {
  let characters = ($buffer | split chars --grapheme-clusters)
  let clean = {|text| $text | ansi strip | str replace --all (char newline) '↵' | str replace --all --regex '[\x00-\x1f\x7f]' ' ' }
  let left = (do $clean ($characters | take $cursor | str join '') | split chars --grapheme-clusters)
  let right = (do $clean ($characters | skip $cursor | str join '') | split chars --grapheme-clusters)
  let budget = ([4 ((($columns - 12) / 2) | math floor | into int)] | math max)
  let right_count = ([($right | length) ($budget // 2)] | math min)
  let left_count = ([($left | length) ($budget - $right_count)] | math min)
  let right_count = ([($right | length) ($budget - $left_count)] | math min)
  let before = ($left | last $left_count | str join '')
  let after = ($right | take $right_count | str join '')
  $"(if $left_count < ($left | length) { '…' })($before)▏($after)(if $right_count < ($right | length) { '…' })"
}

def "menu manage-header" [buffer: string, cursor: int, columns: int] {
  $"命令： (menu edit-preview $buffer $cursor $columns)(char newline)Enter 操作 · Esc 完成 · Backspace 返回(char newline)編輯可連按 Enter · ↑↓ / Tab 選擇(char newline)(menu navigation-hint)"
}

# The private session lets fzf apply repeated edits without returning to Reedline.
# Commit its buffer, cursor and undo stack on Esc, Backspace or another action.
def --env "menu manage-pick" [] {
  let directory = (mktemp --directory)
  let file = ($directory | path join 'state.json')
  let columns = (try { (term size).columns } catch { 80 })
  try {
    let initial = {buffer: (commandline), cursor: (commandline get-cursor), undo: $env.GAMEPAD_UNDO, editing: false, close: false, error: null, columns: $columns}
    $initial | to json | save $file
    let private = (^chmod 600 $file | complete)
    if $private.exit_code != 0 { error make {msg: 'Unable to secure the editing session'} }
    let result = (menu pick (menu management) (menu manage-header $initial.buffer $initial.cursor $columns) --editor-state $file)
    let edited = (open $file)
    if $edited.buffer != $initial.buffer { commandline edit --replace $edited.buffer }
    commandline set-cursor $edited.cursor
    $env.GAMEPAD_UNDO = $edited.undo
    if $edited.error != null { error make {msg: $edited.error} }
    rm --recursive --permanent --force $directory
    $result
  } catch {|err|
    rm --recursive --permanent --force $directory
    error make $err
  }
}

def "menu navigation-hint" [--fuzzy, --browse] {
  let endpoints = (if $fuzzy { 'Home/End 搜尋首尾' } else { 'Home/End 首末項' })
  let pages = (if (not $fuzzy) and (not $browse) { '←→ / PgUp/PgDn 分頁' } else { 'PgUp/PgDn 分頁' })
  $"($endpoints) · ($pages)(char newline)Shift-Tab 上一項"
}

# Like Ctrl-O, edit a temporary copy and stage the result for review. nvim's
# final file newline is not part of the command; preserve any other newlines.
def --env "menu edit" [] {
  let file = (mktemp --suffix .nu)
  try {
    commandline | save --force --raw $file
    ^nvim $file
    if $env.LAST_EXIT_CODE == 0 {
      menu replace (open --raw $file | str replace --regex '\r?\n\z' '')
    }
  } catch {|err|
    rm --permanent --force $file
    error make $err
  }
  rm --permanent --force $file
}

# Reverse before deduplication so the most recent spelling/order wins.
# --long supplies cwd/exit_status for SQLite history; keep multiline commands intact.
def "menu history-data" [--here, --status: string = 'all'] {
  shell history-rows --here=$here --status $status | menu history-items --here=$here --status $status
}

def "menu history-items" [--here, --status: string = 'all', --project: path] {
  let rows = $in
  let current = $env.PWD
  # A typed launcher is recorded before its picker opens. Offering that same
  # launcher as the first result would send keyboard users back into the picker.
  let launcher = '^menu([ \t]+history([ \t]+--global)?|[ \t]+run[ \t]+(main|history_here|history_all))?$'
  $rows | reverse
  | where {|row|
    let directory = ($row.cwd? | default '')
    let code = $row.exit_status?
    ((($row.command | str trim) != '')
      and (($row.command | str trim) !~ $launcher)
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
# Cursor indexes are grapheme clusters; substring indexes are UTF-8 bytes.
def "menu snippet-items" [buffer: string, cursor: int] {
  let rows = $in
  if $cursor <= 0 { return [] }
  let characters = ($buffer | split chars --grapheme-clusters)
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

def "menu snippets" [] {
  let buffer = (commandline)
  let cursor = (commandline get-cursor)
  let prefix = ($buffer | split chars --grapheme-clusters | take $cursor | str join '' | str trim --left)
  if ($prefix | str trim | is-empty) { return [] }
  shell history-rows --prefix $prefix | menu snippet-items $buffer $cursor
}

source gamepad-tools.nu
source gamepad-workflows.nu
source gamepad-tasks.nu

# Browsing does not change PWD or run hooks. Only 'use this directory' stages cd.
# to nuon quotes paths as Nu literals, including spaces, quotes and interpolation.
def "menu directories" [directory: path] {
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

def "menu frequent directories" [] {
  if (which zoxide | is-empty) { return [] }
  let result = (^zoxide query --list | complete)
  if $result.exit_code != 0 { return [] }
  $result.stdout | lines | where {|dir| $dir | path type | $in == dir }
  | each {|dir| {label: $dir, path: $dir} }
}

# Quote the complete pasted script as ONE argument; Nu must not expand its Bash
# variables, substitutions, redirections, or heredocs. Stage only: executing this
# external normally preserves the terminal and LAST_EXIT_CODE in the parent Nu.
# Bash inherits cwd/environment (including BASH_ENV, if configured), but does not
# load login/interactive profiles. Its cd/export/exit only affect the child.
def "menu bash-command" [text: string] {
  menu command bash [--noprofile --norc -c $text]
}

def --env "menu run" [initial_action: string] {
  # Hand the terminal to fzf without leaving Reedline hints or menu rows behind.
  print --no-newline (ansi clear_screen_from_cursor_to_end)
  mut action = $initial_action
  mut directory = $env.PWD
  mut notice = ''
  mut history_query = (if $initial_action in [history_here history_all] { commandline } else { '' })
  mut history_status = 'all'
  mut file_query = ''
  mut root = ''
  loop {
    if $action == main {
      let selected = (menu pick (menu actions) $"($notice)命令選單：↑↓ / Tab 選擇 · Enter 確認 · Backspace / Esc 關閉(char newline)(menu navigation-hint)")
      if $selected.key in [cancel back] { return }
      $action = $selected.item.action
      $notice = ''
      continue
    }
    if $action == manage {
      let selected = (menu manage-pick)
      if $selected.key == cancel { return }
      if $selected.key == back { $action = 'main'; continue }
      $action = $selected.item.action
      continue
    }
    if $action in [insert_paths templates clipboard history_programs drafts tasks] {
      let result = (try {
        match $action {
          insert_paths => {
            let selected = (menu select-paths '選路徑，插入目前指令')
            if $selected.key == enter { menu insert-arguments $selected.paths }
            $selected
          }
          templates => {
            let filled = (menu templates-menu)
            if $filled.key == enter { menu replace $filled.command }
            $filled
          }
          clipboard => { menu clipboard-menu }
          history_programs => {
            let selected = (menu history-program-menu)
            if $selected.key == enter { menu replace $selected.command }
            $selected
          }
          drafts => { menu drafts-menu }
          tasks => { menu tasks-menu }
        }
      } catch {|err| {key: back, notice: $err.msg} })
      if $result.key != back { return }
      $notice = ($result.notice? | default '') + (char newline)
      $action = 'main'
      continue
    }
    if $action == clear {
      if (commandline | is-not-empty) { menu replace '' }
      return
    }
    if $action in (menu edit-actions) {
      menu edit-line $action
      $action = 'manage'
      continue
    }
    if $action == edit {
      menu edit
      return
    }
    if $action == bash {
      let text = (commandline)
      if ($text | str trim | is-empty) {
        $notice = $"請先將要用 Bash 執行的文字貼入命令列。(char newline)"
        $action = 'main'
        continue
      }
      if (which bash | is-empty) {
        $notice = $"找不到 Bash；請確認 bash 在 PATH 中。(char newline)"
        $action = 'main'
        continue
      }
      menu replace (menu bash-command $text)
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
        let favorites = (menu favorites)
        if not ($favorites | any {|item| $item.command == $command }) {
          $favorites | append {label: $command, command: $command}
          | save --force $env.GAMEPAD_FAVORITES_FILE
        }
      }
      return
    }
    if $action =~ '^git' {
      let repository = (menu git-root)
      if $repository == null {
        $notice = $"目前目錄不是 Git 專案，請先用「瀏覽目錄」切換到專案。(char newline)"
        $action = 'main'
        continue
      }
      $root = $repository
    } else if ($root == '') and ($action =~ '^(project|files)') {
      $root = (menu project-root)
    }
    let items = (match $action {
      favorites | remove_favorite => { menu favorites }
      history_here => { menu history-data --here --status $history_status }
      history_all => { menu history-data --status $history_status }
      snippets => { menu snippets }
      directories => { menu directories $directory }
      frequent => { menu frequent directories }
      project => { menu project-items $root }
      project_recent => { menu project-recent $root }
      project_nur => { menu project-tasks $root nur }
      project_just => { menu project-tasks $root just }
      project_make => { menu project-tasks $root make }
      files => { [
        {label: '瀏覽目前目錄與子目錄', action: files_browser}
        {label: '搜尋專案檔案（含未追蹤檔案）', action: files_project}
      ] }
      files_browser => { menu file-entries $directory }
      files_project => { menu project-files $root }
      git => { menu git-items $root }
      git_files => { menu git-files $root }
      git_branches => { menu git-branches $root }
      tmux => { menu tmux-items }
    })
    let is_history = ($action in [history_here history_all])
    let is_files = ($action in [files_browser files_project])
    if ($items | is-empty) and (not $is_history) and (not $is_files) {
      $notice = (if $action == snippets {
        $"找不到可接續的歷史片段；請先輸入曾使用的指令前綴。(char newline)"
      } else { $"沒有可用項目，請選擇其他功能。(char newline)" })
      $action = (menu parent $action)
      continue
    }
    let fuzzy = ($is_history or ($action in [snippets files_project git_files git_branches project_recent tmux]))
    let context = (if $action == snippets {
      $"插入歷史片段：依游標前文字比對 · 目前目錄優先(char newline)"
    } else if $action =~ '^(project|git|files_project)' { $"專案：($root)(char newline)" } else { '' })
    let title = (if $action == files_browser {
      $"檔案：目錄瀏覽 · ($directory)(char newline)Tab 切換專案搜尋 · ↑↓ 選擇 · ← / Backspace 上一層 · → / Enter 進入 · Esc 關閉"
    } else if $action == files_project {
      $"($context)檔案：專案搜尋 · Tab 切換目錄瀏覽(char newline)輸入文字搜尋 · ↑↓ 選擇 · Enter 確認 · Backspace 刪字／空白返回 · Esc 關閉"
    } else if $action == directories {
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
    let header = $"($title)(char newline)(menu navigation-hint --fuzzy=$fuzzy --browse=($action in [directories files_browser]))"
    let selected = (menu pick $items $header --browse=($action in [directories files_browser]) --fuzzy=$fuzzy --history-controls=$is_history --file-controls=$is_files --query (if $is_history { $history_query } else if $action == files_project { $file_query } else { '' }))
    if $selected.key == cancel { return }
    $notice = ''
    if $is_files and ($selected.key == tab) {
      if $action == files_project { $file_query = $selected.query }
      $action = (if $action == files_browser { 'files_project' } else { 'files_browser' })
      continue
    }
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
      if $action == files_project { $file_query = '' }
      if ($action in [directories files_browser]) and ($directory != ($directory | path dirname)) {
        $directory = ($directory | path dirname)
      } else { $action = (menu parent $action) }
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
        menu replace $"cd ($directory | to nuon)"
        return
      } else if $selected.item.kind == file {
        menu replace (menu command nvim [-- $selected.item.path])
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
      menu insert $selected.item.snippet
      return
    }
    if ($selected.item.parameters? | default [] | is-not-empty) {
      let filled = (menu fill-template $selected.item)
      if $filled.key == enter { menu replace $filled.command; return }
      if $filled.key == cancel { return }
      continue
    }
    menu replace $selected.item.command
    return
  }
}

def "menu actions" [] {
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
    {label: '用 Bash 執行目前文字（先預覽，再按 Enter）', action: bash}
    {label: '選檔案／目錄，插入目前指令', action: insert_paths}
    {label: '參數化收藏（逐欄選值）', action: templates}
    {label: '剪貼簿與 cb 暫存', action: clipboard}
    {label: '免打字歷史篩選（先選程式）', action: history_programs}
    {label: '命令草稿（暫存／恢復）', action: drafts}
    {label: 'tmux 任務（執行／查看／中止／重跑）', action: tasks}
    {label: '管理收藏與命令列', action: manage}
  ]
}

def "menu management" [] {
  [
    {label: '收藏目前命令', action: add_favorite}
    {label: '移除收藏', action: remove_favorite}
    {label: '清空命令列', action: clear}
    {label: '復原選單變更', action: undo}
    {label: '游標移到目前行首', action: line_start}
    {label: '游標移到目前行尾', action: line_end}
    {label: '刪除前一個詞（依空白分隔）', action: delete_word}
    {label: '游標左移一字元', action: previous_char}
    {label: '游標右移一字元', action: next_char}
    {label: '游標移到前一個詞', action: previous_word}
    {label: '游標移到下一個詞', action: next_word}
    {label: '刪除後一個詞（依空白分隔）', action: delete_next_word}
    {label: '刪除游標前一字元', action: delete_previous_char}
    {label: '刪除游標後一字元', action: delete_next_char}
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
# Override the built-in history_menu by name: Nu restores omitted default names.
$env.config.keybindings = ($env.config.keybindings | where {|binding|
  ($binding.name !~ '^gamepad_') and not (
    (($binding.modifier | str lowercase) == 'control') and ($binding.keycode == 'char_r')
  )
} | append [
  {
    name: gamepad_menu, modifier: none, keycode: esc, mode: [emacs]
    # MenuUp only applies to an open completion menu. Close that menu before
    # repainting; otherwise ExecuteHostCommand opens fzf and ends this event chain.
    event: [
      {until: [{send: menuup}, {send: executehostcommand, cmd: 'menu run main'}]}
      {send: esc}
    ]
  }
  {
    name: history_menu, modifier: control, keycode: char_r, mode: [emacs vi_insert vi_normal]
    event: {send: executehostcommand, cmd: 'menu run history_here'}
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

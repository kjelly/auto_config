# Controller workflows build text from selected data, never eval selected text.
# Drafts/clipboard stay in this Nu session; do not persist command text to disk.
$env.GAMEPAD_DRAFTS = ($env.GAMEPAD_DRAFTS? | default [])

def "menu choose" [items: list<record>, title: string, --fuzzy] {
  menu pick $items $"($title)(char newline)↑↓ / Tab 選擇 · Enter 確認 · Backspace 返回 · Esc 關閉(char newline)(menu navigation-hint --fuzzy=$fuzzy)" --fuzzy=$fuzzy
}

def "menu argument-text" [values: list<string>] {
  $values | each {|value| $value | to nuon } | str join ' '
}

def --env "menu insert-arguments" [values: list<string>] {
  if ($values | is-empty) { return }
  let chars = (commandline | split chars --grapheme-clusters)
  let cursor = (commandline get-cursor)
  let before = ($chars | take $cursor | last | default '')
  let after = ($chars | skip $cursor | first | default '')
  let leading = (if ($before != '') and ($before !~ '\s') { ' ' } else { '' })
  let trailing = (if ($after != '') and ($after !~ '\s') { ' ' } else { '' })
  menu insert $"($leading)(menu argument-text $values)($trailing)"
}

# Multi-select uses Space; Tab keeps its normal controller navigation meaning.
# In search results Enter toggles a path, so spaces remain available for queries.
def "menu select-paths" [title: string, --kind: string = 'any', --single] {
  mut directory = $env.PWD
  mut selected = []
  mut search = false
  loop {
    let entries = (if $search {
      menu project-files (menu project-root) | each {|item| {label: $item.label, path: $item.path, kind: file} }
    } else { menu file-entries $directory })
    let checked = $selected
    let location = $directory
    let paths = ($entries | where {|item| ($kind != directory) or ($item.kind == directory) }
      | each {|item| $item | update label $"(if $item.path in $checked { '☑ ' } else { '☐ ' })($item.label)" })
    let controls = (if $search { [] } else { [
      {label: $"✓ 完成，插入已選 ($selected | length) 項", kind: apply}
      {label: '✓ 使用此目錄', kind: use, path: $directory}
      {label: '搜尋專案檔案', kind: search}
    ] | where {|item| not (($kind == file) and ($item.kind == use)) or (not $single) } })
    let items = ($controls | append $paths)
    let hint = (if $search { 'Enter 勾選檔案後返回瀏覽 · Backspace 空白時返回瀏覽' } else { 'Space 勾選 · Enter 進入目錄／選檔 · ← / Backspace 上一層' })
    let choice = (menu pick $items $"($title)：($directory)(char newline)($hint) · 已選 ($selected | length) 項(char newline)(menu navigation-hint --fuzzy=$search --browse=(not $search))" --fuzzy=$search --browse=(not $search) --path-controls=(not $search))
    if $choice.key == cancel { return {key: cancel} }
    if $choice.key == back {
      if $search { $search = false; continue }
      if $directory == $env.PWD { return {key: back} }
      $directory = ($directory | path dirname)
      continue
    }
    if $choice.key == left { $directory = ($directory | path dirname); continue }
    let item = $choice.item
    if $item.kind == apply {
      if $single and (($selected | length) != 1) { continue }
      return {key: enter, paths: $selected}
    }
    if $item.kind == search { $search = true; continue }
    if $item.kind == use {
      if $kind == file { continue }
      if $single { return {key: enter, paths: [$directory]} }
      $selected = (if $directory in $selected { $selected | where {|p| $p != $location } } else { $selected | append $directory })
      continue
    }
    if ($item.kind == directory) and ($choice.key != toggle) {
      $directory = $item.path
      continue
    }
    if ($kind != any) and ($item.kind != $kind) { continue }
    if $single { return {key: enter, paths: [$item.path]} }
    $selected = (if $item.path in $checked { $selected | where {|p| $p != $item.path } } else { $selected | append $item.path })
    $search = false
  }
}

# Parameter placeholders are replaced once from the original template. A chosen
# value containing another placeholder must remain literal data.
# Custom favorites may add parameters, e.g.:
# {label: '比較', command: '^diff -- {{a}} {{b}}', parameters: [
#   {name: a, label: '第一個檔案', kind: file}
#   {name: b, label: '第二個檔案', kind: file}
# ]}
# Placeholders stand alone, without surrounding quotes. Values are Nu literals.
# Kinds: file/directory/any, choice (choices: list<string>), history, clipboard.
def "menu validate-template" [template: record] {
  let parameters = $template.parameters
  let names = ($parameters | get name)
  if ($names | uniq | length) != ($names | length) { error make {msg: '範本欄位名稱不能重複。'} }
  for parameter in $parameters {
    if ($parameter.name | describe) != string or ($parameter.name !~ '^[a-zA-Z_][a-zA-Z0-9_]*$') {
      error make {msg: '範本欄位名稱只能包含英文字母、數字與底線。'}
    }
    if $parameter.kind not-in [file directory any choice history clipboard] { error make {msg: '不支援的範本欄位類型。'} }
    let pattern = ('(^|\s)\{\{' + $parameter.name + '\}\}(\s|$)')
    if $template.command !~ $pattern { error make {msg: $"欄位 ($parameter.name) 必須是未加引號的獨立 {{name}} 參數。"} }
    if $parameter.kind == choice {
      if ($parameter.choices? | describe) !~ '^list|^table' { error make {msg: 'choice 欄位需要 choices 字串列表。'} }
      if ($parameter.choices | is-empty) or ($parameter.choices | any {|value| ($value | describe) != string }) {
        error make {msg: 'choices 必須包含至少一個字串。'}
      }
    }
  }
}

def "menu render-template" [template: record, values: record] {
  menu validate-template $template
  let parameters = ($template.parameters? | default [])
  mut output = $template.command
  let matches = ($template.command | parse --regex '\{\{(?<name>[a-zA-Z_][a-zA-Z0-9_]*)\}\}')
  for entry in ($matches | reverse) {
    if $entry.name not-in ($parameters | get name) { error make {msg: $"未知範本欄位：($entry.name)"} }
  }
  # Split the original text, then substitute each isolated placeholder exactly once.
  let chunks = ($template.command | split row --regex '(\{\{[a-zA-Z_][a-zA-Z0-9_]*\}\})')
  $output = ($chunks | enumerate | each {|chunk|
    if $chunk.index < ($matches | length) {
      let name = ($matches | get $chunk.index | get name)
      $chunk.item + (($values | get $name) | to nuon)
    } else { $chunk.item }
  } | str join '')
  $output
}

def "menu template-items" [] {
  menu favorites | where {|item| ($item.parameters? | default [] | is-not-empty) }
  | append [
    {label: '比較兩個檔案', command: '^diff -- {{left}} {{right}}', parameters: [
      {name: left, label: '第一個檔案', kind: file}
      {name: right, label: '第二個檔案', kind: file}
    ]}
    {label: '複製檔案到目錄（保留既有檔案）', command: '^cp -n -- {{source}} {{target}}', parameters: [
      {name: source, label: '來源檔案', kind: file}
      {name: target, label: '目標目錄', kind: directory}
    ]}
    {label: '列出目錄內容', command: 'ls {{directory}}', parameters: [
      {name: directory, label: '要瀏覽的目錄', kind: directory}
    ]}
  ]
}

def "menu fill-template" [template: record] {
  menu validate-template $template
  let parameters = $template.parameters
  mut values = {}
  mut index = 0
  while $index < ($parameters | length) {
    let parameter = ($parameters | get $index)
    let title = $"($template.label) · ($index + 1)/($parameters | length)：($parameter.label? | default $parameter.name)"
    let result = (match $parameter.kind {
      file | directory | any => { menu select-paths $title --kind $parameter.kind --single }
      choice => {
        let choice = (menu choose ($parameter.choices | each {|value| {label: $value, value: $value} }) $title)
        if $choice.key == enter { {key: enter, paths: [$choice.item.value]} } else { $choice }
      }
      history => {
        let choice = (menu history-program-menu)
        if $choice.key == enter { {key: enter, paths: [$choice.command]} } else { $choice }
      }
      clipboard => {
        let clip = (menu clipboard-read)
        if $clip.ok { {key: enter, paths: [$clip.text]} } else { error make {msg: $clip.error} }
      }
      _ => { error make {msg: $"不支援的範本欄位類型：($parameter.kind)"} }
    })
    if $result.key == cancel { return $result }
    if $result.key == back {
      if $index == 0 { return $result }
      $index -= 1
      continue
    }
    $values = ($values | upsert $parameter.name ($result.paths | first))
    $index += 1
  }
  {key: enter, command: (menu render-template $template $values)}
}

def "menu templates-menu" [] {
  loop {
    let selected = (menu choose (menu template-items) '參數化收藏')
    if $selected.key in [back cancel] { return $selected }
    let filled = (menu fill-template $selected.item)
    if $filled.key != back { return $filled }
  }
}

# Prefer the active display protocol; fall back to tmux's own paste buffer.
# Read stdout verbatim: trailing newlines are part of clipboard content.
def "menu clipboard-backends" [--write] {
  [
    {program: (if $write { 'wl-copy' } else { 'wl-paste' }), args: (if $write { [] } else { ['--no-newline'] }), enabled: (($env.WAYLAND_DISPLAY? | default '') != '')}
    {program: xclip, args: ([ -selection clipboard ] ++ (if $write { ['-in'] } else { ['-out'] })), enabled: (($env.DISPLAY? | default '') != '')}
    {program: xsel, args: ([--clipboard] ++ (if $write { ['--input'] } else { ['--output'] })), enabled: (($env.DISPLAY? | default '') != '')}
    {program: (if $write { 'pbcopy' } else { 'pbpaste' }), args: [], enabled: ($nu.os-info.name == macos)}
    {program: tmux, args: (if $write { ['load-buffer' '-'] } else { ['show-buffer'] }), enabled: (($env.TMUX? | default '') != '')}
  ] | where {|item| $item.enabled and (which $item.program | is-not-empty) }
}

def "menu clipboard-read" [] {
  for backend in (menu clipboard-backends) {
    let result = (run-external $backend.program ...$backend.args | complete)
    if $result.exit_code == 0 { return {ok: true, text: $result.stdout, backend: $backend.program} }
  }
  {ok: false, error: '無法讀取剪貼簿；需要可用的 wl-paste、xclip、xsel、pbpaste 或 tmux buffer。'}
}

def "menu clipboard-write" [text: string] {
  for backend in (menu clipboard-backends --write) {
    let result = ($text | run-external $backend.program ...$backend.args | complete)
    if $result.exit_code == 0 { return {ok: true, backend: $backend.program} }
  }
  {ok: false, error: '無法寫入剪貼簿；需要可用的 wl-copy、xclip、xsel、pbcopy 或 tmux buffer。'}
}

def --env "menu clipboard-menu" [] {
  mut notice = ''
  loop {
    let selected = (menu choose [
      {label: '貼上剪貼簿（原文，桌面優先）', mode: system_raw}
      {label: '貼上剪貼簿（單一字串參數，桌面優先）', mode: system_argument}
      {label: '選擇 cb 暫存內容（原文）', mode: cb_raw}
      {label: '選擇 cb 暫存內容（單一字串參數）', mode: cb_argument}
      {label: '複製目前命令到剪貼簿（桌面優先）', mode: copy}
      {label: '將目前命令加入 cb 暫存', mode: save}
    ] $"剪貼簿（桌面不可用時使用 tmux buffer）· ($notice)")
    if $selected.key in [cancel back] { return $selected }
    let mode = $selected.item.mode
    if $mode == save {
      if (commandline | is-not-empty) { $env._clipboard = ($env._clipboard? | default [] | append (commandline) | last 10) }
      $notice = '已加入 cb 暫存'
      continue
    }
    if $mode == copy {
      let result = (menu clipboard-write (commandline))
      $notice = (if $result.ok { '已複製' } else { $result.error })
      continue
    }
    let result = (if ($mode | str starts-with cb_) {
      let items = ($env._clipboard? | default [] | reverse | each {|value|
        let text = (if ($value | describe) == string { $value } else { $value | to nuon })
        {label: $text, text: $text}
      })
      if ($items | is-empty) { {ok: false, error: 'cb 暫存目前沒有內容'} } else {
        let chosen = (menu choose $items '選擇 cb 暫存內容')
        if $chosen.key == cancel { return $chosen }
        if $chosen.key == back { {ok: false, error: ''} } else { {ok: true, text: $chosen.item.text} }
      }
    } else { menu clipboard-read })
    if not $result.ok { $notice = $result.error; continue }
    if ($mode | str ends-with argument) { menu insert-arguments [$result.text] } else { menu insert $result.text }
    return {key: enter}
  }
}

def "menu history-program" [command: string] {
  $command | str trim --left | parse --regex '^\^?(?<program>[^\s;|]+)' | get -o 0.program | default '(其他)'
}

def "menu history-program-items" [] {
  $in | each {|row| {program: (menu history-program $row.command)} }
  | group-by program | transpose program rows
  | each {|group| {label: $"($group.program)（($group.rows | length) 筆）", program: $group.program} }
}

def "menu history-program-menu" [] {
  mut here = true
  mut status = 'all'
  mut program: any = null
  loop {
    let rows = (menu history-data --here=$here --status $status)
    let selected_program = $program
    let items = (if $program == null {
      [{label: '全部程式', program: ''}] | append ($rows | menu history-program-items)
    } else { $rows | where {|row| ($selected_program == '') or ((menu history-program $row.command) == $selected_program) } })
    let scope = (if $here { '目前目錄' } else { '全域' })
    let state = (match $status { success => { '成功' }, failed => { '失敗或中斷' }, _ => { '全部' } })
    let choice = (menu pick $items $"免打字歷史：($scope) / ($state) / ($program | default '選程式')(char newline)← 目前目錄 · → 全域 · Tab 切換狀態(char newline)Enter 確認 · Backspace 返回 · Esc 關閉(char newline)(menu navigation-hint)" --history-controls)
    if $choice.key == cancel { return $choice }
    if $choice.key in [left right tab] {
      if $choice.key == tab { $status = (match $status { all => { 'success' }, success => { 'failed' }, _ => { 'all' } }) } else { $here = ($choice.key == left) }
      continue
    }
    if $choice.key == back {
      if $program == null { return $choice }
      $program = null
      continue
    }
    if $program == null { $program = $choice.item.program } else { return {key: enter, command: $choice.item.command} }
  }
}

def --env "menu drafts-menu" [] {
  loop {
    let choice = (menu choose [
      {label: '暫存目前指令並清空（保留游標）', action: save}
      {label: $"恢復草稿（($env.GAMEPAD_DRAFTS | length) 份）", action: restore}
      {label: '刪除一份草稿', action: delete}
    ] '命令草稿 · 僅保存在目前 Nu 工作階段，最多 20 份')
    if $choice.key in [cancel back] { return $choice }
    if $choice.item.action == save {
      if (commandline | is-not-empty) {
        $env.GAMEPAD_DRAFTS = ($env.GAMEPAD_DRAFTS | append {buffer: (commandline), cursor: (commandline get-cursor), cwd: $env.PWD} | last 20)
        menu replace ''
      }
      return {key: enter}
    }
    if ($env.GAMEPAD_DRAFTS | is-empty) { continue }
    let items = ($env.GAMEPAD_DRAFTS | enumerate | reverse | each {|draft|
      {label: $"[($draft.item.cwd)] ($draft.item.buffer)", index: $draft.index, draft: $draft.item}
    })
    let selected = (menu choose $items '選擇草稿 · 還原文字與游標，保留目前目錄')
    if $selected.key == cancel { return $selected }
    if $selected.key == back { continue }
    if $choice.item.action == delete {
      $env.GAMEPAD_DRAFTS = ($env.GAMEPAD_DRAFTS | drop nth $selected.item.index)
      continue
    }
    menu replace $selected.item.draft.buffer
    commandline set-cursor $selected.item.draft.cursor
    return {key: enter}
  }
}

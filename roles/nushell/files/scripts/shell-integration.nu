# Nushell 0.116 supplies already-expanded aliases in place.command.
# null delegates unsupported, missing or failed completers to native file completion.
def shell-complete [place: record] {
  try {
    let spans = $place.command
    if ($spans | is-empty) or (which carapace | is-empty) { return null }
    let result = (^carapace $spans.0 nushell ...$spans | complete)
    if $result.exit_code != 0 { return null }
    let values = ($result.stdout | from json)
    if ($values | describe) !~ '^list|^table' { return null }
    if ($values | any {|value|
      let kind = ($value | describe)
      if $kind == string { false } else if ($kind | str starts-with 'record') {
        ($value.value? | describe) != string
      } else { true }
    }) { return null }
    if ($values | is-empty) { null } else { $values }
  } catch { null }
}

def --env refresh-eink-env [] {
  if ($env.GAMEPAD_TASK_RUNNING? | default '') == '1' { return }
  if ($env.TMUX? | default '' | is-empty) or (which tmux | is-empty) { return }
  let result = (^tmux show-environment -g EINK_WIDTH | complete)
  $env.EINK_WIDTH = (if $result.exit_code == 0 {
    try { $result.stdout | str trim | str replace 'EINK_WIDTH=' '' | into int } catch { 0 }
  } else { 0 })
}

def shell-theme-palette [mode: string] {
  match $mode {
    light => { default: default, muted: '#505050', blue: '#005faf', green: '#006400', cyan: '#006060', purple: '#800080', yellow: '#805500', red: '#a00000' }
    dark => { default: default, muted: '#b0b0b0', blue: '#80bfff', green: '#80d080', cyan: '#70d0d0', purple: '#d0a0ff', yellow: '#e0c070', red: '#ff9090' }
    _ => { default: default, muted: default, blue: default, green: default, cyan: default, purple: default, yellow: default, red: default }
  }
}

# Map the standard theme's semantic colors to a high-contrast palette. Auto uses
# SGR 39 (the terminal foreground), so changing OSC 10/11 needs no color query.
def shell-theme-style [style: any, palette: record] {
  if ($style | describe) =~ '^record' {
    return {fg: default, attr: ($style.attr? | default 'n')}
  }
  let name = ($style | str replace --regex '^light_' '' | split row '_')
  let color = (match $name.0 {
    dark => 'muted'
    grey42 => 'muted'
    darkcyan => 'cyan'
    _ => $name.0
  })
  {fg: ($palette | get -o $color | default default), attr: (if 'bold' in $name { 'b' } else if 'underline' in $name { 'u' } else { 'n' })}
}

# nu-theme auto follows black-on-white and white-on-black terminals immediately.
# Use light/dark for explicit color, or set NU_THEME in custom.nu to persist it.
def --env nu-theme [mode: string = 'auto'] {
  if $mode not-in [auto light dark] {
    error make {msg: 'Usage: nu-theme [auto|light|dark]'}
  }
  $env.NU_THEME = $mode
  update-nushell-theme --force
}

def --env update-nushell-theme [--force] {
  # A task's batch Nu does not render the interactive prompt. In particular,
  # don't query its terminal from display_output after a command is interrupted.
  if ($env.GAMEPAD_TASK_RUNNING? | default '') == '1' { return }
  let requested = ($env.NU_THEME? | default 'auto')
  let mode = (if $requested in [auto light dark] { $requested } else { 'auto' })
  let state = {version: 2, mode: $mode, ls_colors: ($env.LS_COLORS? | default '')}
  if (not $force) and ($env.NU_THEME_STATE? == $state) { return }
  let palette = (shell-theme-palette $mode)
  use std/config dark-theme
  $env.config.color_config = (dark-theme | items {|key, style|
    {($key): (shell-theme-style $style $palette)}
  } | reduce --fold {} {|entry, acc| $acc | merge $entry } | merge {
    hints: {fg: $palette.muted, attr: u}
    search_result: {fg: default, attr: r}
    shape_garbage: {fg: default, attr: ru}
    selection: {fg: default, attr: r}
    selection_cursor: {fg: default, attr: ru}
  })

  # ls filenames have their own styles, independent of color_config. Replace
  # inherited background colors too (sticky/writable dirs, setuid files, etc.).
  let sgr = ($palette | items {|key, color|
    {($key): (if $color == default { '39' } else {
      let rgb = ($color | str substring 1.. | split chars | chunks 2 | each {|pair| $pair | str join | into int --radix 16 })
      $"38;2;($rgb | each { into string } | str join ';')"
    })}
  } | reduce --fold {} {|entry, acc| $acc | merge $entry })
  $env.LS_COLORS = ([
    'rs=0' $"no=($sgr.default)" $"fi=($sgr.default)"
    $"di=1;($sgr.blue)" $"ln=4;($sgr.cyan)" $"ex=1;4;($sgr.green)"
    $"or=1;4;($sgr.red)" $"mi=1;4;($sgr.red)"
    $"pi=($sgr.yellow)" $"so=1;($sgr.purple)" $"do=($sgr.purple)"
    $"bd=1;($sgr.yellow)" $"cd=1;($sgr.yellow)"
    $"su=1;4;($sgr.red)" $"sg=1;4;($sgr.red)" $"ca=1;4;($sgr.red)"
    $"tw=1;($sgr.blue)" $"ow=1;($sgr.blue)" $"st=1;($sgr.blue)"
    $"mh=($sgr.default)"
  ] | str join ':')
  $env.config.ls.use_ls_colors = true
  $env.config.menus = ($env.config.menus | each {|menu|
    $menu | upsert style {
      text: {fg: default}
      selected_text: {fg: default, attr: r}
      description_text: {fg: $palette.muted}
      match_text: {fg: default, attr: u}
      selected_match_text: {fg: default, attr: ru}
    }
  })
  $env.config.explore = ($env.config.explore | merge {
    status: {success: {fg: default, attr: b}, error: {fg: default, attr: ru}}
    selected_cell: {fg: default, attr: r}
    highlight: {fg: default, attr: ru}
  })
  $env.NU_THEME_STATE = ($state | upsert ls_colors $env.LS_COLORS)
}

def my-prompt [] {
  # Capture these before invoking anything external, which updates LAST_EXIT_CODE.
  let status = ($env.LAST_EXIT_CODE? | default 0)
  let duration = ($env.CMD_DURATION_MS? | default 0)
  try {
    if (which starship | is-not-empty) {
      let result = (^starship prompt $"--status=($status)" --cmd-duration $duration | complete)
      if $result.exit_code == 0 { return $result.stdout }
    }
  }
  $"($env.PWD) "
}

def --env shell-directory-env [] {
  if (which direnv | is-not-empty) {
    if ('auto-direnv' | path exists) { ^direnv allow . | complete | ignore }
    let result = (^direnv export json | complete)
    if ($result.exit_code == 0) and ($result.stdout | str trim | is-not-empty) {
      let changes = (try { $result.stdout | from json } catch { {} })
      if ($changes | describe) =~ '^record' {
        for entry in ($changes | transpose name value) {
          if $entry.name in [PWD FILE_PWD CURRENT_FILE] { continue }
          if $entry.value == null { hide-env --ignore-errors $entry.name } else {
            let value = (if $entry.name == PATH {
              if ($entry.value | describe) == string { $entry.value | split row (char esep) } else { $entry.value }
            } else { $entry.value })
            load-env {($entry.name): $value}
          }
        }
      }
    }
  }
  if (which zoxide | is-not-empty) { ^zoxide add -- $env.PWD | complete | ignore }
}

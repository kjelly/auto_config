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

def --env update-nushell-theme [] {
  # A task's batch Nu does not render the interactive prompt. In particular,
  # don't query its terminal from display_output after a command is interrupted.
  if ($env.GAMEPAD_TASK_RUNNING? | default '') == '1' { return }
  let columns = (try { (term size).columns } catch { 0 })
  let width = (try { $env.EINK_WIDTH? | default 0 | into int } catch { 0 })
  let state = {columns: $columns, width: $width}
  if $env.NU_THEME_STATE? == $state { return }
  use std/config [light-theme dark-theme]
  $env.config.color_config = (if ($width > 0) and ($columns == $width) {
    light-theme | upsert hints dark_gray_bold
  } else { dark-theme | upsert hints cyan })
  $env.NU_THEME_STATE = $state
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

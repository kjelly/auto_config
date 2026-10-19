# Only login.nu sources this file: ordinary child shells inherit the environment.
# NUL separates entries, so exported multiline values and '=' survive intact.
def --env import-login-profile [] {
  let profile = ($env.HOME | path join '.profile')
  if not ($profile | path exists) { return }
  let env_program = (which env | get 0.path)
  let result = (^bash -c 'source "$1" >&2 && "$2" -0' nu-login $profile $env_program | complete)
  if $result.exit_code != 0 { return }
  let ignored = ['_' SHLVL PWD OLDPWD FILE_PWD CURRENT_FILE LAST_EXIT_CODE CMD_DURATION_MS DIRS_POSITION]
  let changes = ($result.stdout | split row (char nul) | where {|entry| $entry | str contains '=' }
    | each {|entry| $entry | split row '=' --number 2 }
    | where {|entry| $entry.0 not-in $ignored }
    | reduce --fold {} {|entry, acc| $acc | upsert $entry.0 $entry.1 })
  let changes = (if 'PATH' in $changes { $changes | update PATH {|row| $row.PATH | split row (char esep) } } else { $changes })
  load-env $changes
}
import-login-profile

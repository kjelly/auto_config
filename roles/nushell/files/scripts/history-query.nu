# Keep filtering close to SQLite. Bind every value: paths and incomplete shell
# text are data, never SQL. The native reader remains available for text history.
def "shell history-rows" [--here, --status: string = 'all', --project: path, --prefix: string = ''] {
  let default_database = (if ($nu.history-path | path parse | get extension) in [sqlite sqlite3 db] {
    $nu.history-path
  } else { $nu.history-path | path dirname | path join 'history.sqlite3' })
  let database = ($env.NU_HISTORY_DATABASE? | default $default_database)
  if (($env.config.history.file_format == 'sqlite') or ($env.NU_HISTORY_DATABASE? != null)) and ($database | path exists) {
    let result = (try {
      mut conditions = ['1 = 1']
      mut params = []
      if $here { $conditions ++= ['cwd = ?']; $params ++= [$env.PWD] }
      if $project != null {
        let child = $"($project | str trim -r -c '/')/"
        $conditions ++= ['(cwd = ? OR substr(cwd, 1, length(?)) = ?)']
        $params ++= [$project $child $child]
      }
      if $status == success { $conditions ++= ['exit_status = 0'] }
      if $status == failed { $conditions ++= ['exit_status IS NOT NULL AND exit_status != 0'] }
      if $prefix != '' {
        # Rust str::trim whitespace, matching snippet-items including Unicode.
        let whitespace = (" \t\n\r" + (char -u '000b') + (char -u '000c') + (char -u '0085') + (char -u '00a0') + (char -u '1680') + "           " + (char -u '2028') + (char -u '2029') + (char -u '202f') + (char -u '205f') + (char -u '3000'))
        $conditions ++= ['instr(ltrim(command_line, ?), ?) = 1']
        $params ++= [$whitespace $prefix]
      }
      # Ascending id preserves native history order; callers reverse for recency.
      open $database | query db $"SELECT command_line AS command, cwd, exit_status FROM history WHERE ($conditions | str join ' AND ') ORDER BY id" --params $params
    } catch { null })
    if $result != null { return $result }
  }
  try { history --long } catch { [] }
}

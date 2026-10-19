# fzf's short-lived workers only manipulate a private session; never evaluate
# command text or start an interactive shell. Reuse exactly the same edit rules.
source gamepad.nu

def main [operation: string, file: path, index?: int] {
  let initial = (open $file)
  mut state = $initial
  if $operation == header {
    let columns = (try { $env.FZF_COLUMNS? | default $initial.columns | into int } catch { $initial.columns })
    return (menu manage-header $state.buffer $state.cursor $columns)
  }
  if $operation == control {
    return (if $state.close or ($state.error != null) { 'print(enter)+accept' } else { 'ignore' })
  }
  if $operation != apply { error make {msg: 'Unknown editor operation'} }
  let original = $state
  let outcome = (try {
    let action = (menu management | get $index | get action)
    if $action in (menu edit-actions) {
      let edited = (menu line-edit $state.buffer $state.cursor $action)
      if ($edited.buffer != $state.buffer) or ($edited.cursor != $state.cursor) {
        $state.undo = ($state.undo | append {buffer: $state.buffer, cursor: $state.cursor} | last 20)
        $state.buffer = $edited.buffer
        $state.cursor = $edited.cursor
      }
      $state.editing = true
    } else if $state.editing and ($action == undo) {
      if ($state.undo | is-not-empty) {
        let previous = ($state.undo | last)
        $state.undo = ($state.undo | drop 1)
        $state.buffer = $previous.buffer
        $state.cursor = $previous.cursor
      }
    } else if $state.editing and ($action == clear) {
      if $state.buffer != '' {
        $state.undo = ($state.undo | append {buffer: $state.buffer, cursor: $state.cursor} | last 20)
        $state.buffer = ''
        $state.cursor = 0
      }
    } else { $state.close = true }
    $state
  } catch {|err| $original | upsert error $err.msg })
  # transform-header is synchronous, so actions cannot race each other's writes.
  $outcome | to json | save --force $file
  if $outcome.close or ($outcome.error != null) { '' | save --force ($file + '.close') }
  let columns = (try { $env.FZF_COLUMNS? | default $initial.columns | into int } catch { $initial.columns })
  menu manage-header $outcome.buffer $outcome.cursor $columns
}

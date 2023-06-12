let-env _clipboard = ( try { $env._clipboard } catch { [ ] })

def pretty [  ] {
  let it = $in
  let type = ( $it | describe )
  if ( $type == "string" ) {
    $it | lines|first 5|str join "\n"
  } else if ( $type == "int" ) {
    $it |into string
  } else if ( $type | str contains "list" ) {
    $it | first 5 | to nuon
  } else {
    $it | describe
  }
}

def-env cb [ command = "" ] {
  if ( $command | is-empty ) {
    let stdin = $in
    if ( $stdin | is-empty ) {
    } else {
      let-env _clipboard = ( $env._clipboard | append [$stdin] | last 10)
    }
    return ($env._clipboard | last)
  } else {
    try {
      let index = ( $command | into int )
      let length = ( $env._clipboard | length )
      return ($env._clipboard | get ( ($length ) - $index - 1))
    } catch {
      if ( $command == "list" ) {
        return ($env._clipboard |par-each {|it|
          $it |pretty
        }|reverse)
      } else if ( $command == "clear" ) {
        let-env _clipboard = [ ]
        return $env._clipboard
      } else if ( $command == "fzf" ) {
        $env._clipboard | fzf_list
      } else {
        echo "invalid command"
      }
    }
  }
}

def fzf_list [ ] {
  let stdin = $in
  let map_list = ($stdin | enumerate | each {|it| 
    let index = ($it |get index)
    let value = ($it |get item )
    { index : $index, value: $value}
  })
  $map_list
  let selected = ($map_list|each {|it| 
    { index: $it.index, value: ($it.value |pretty| str replace -a "\n" "")}|to nuon
  }|str join "\n"|^fzf|str trim)

  let selectedIndex = ($selected|into string|from nuon).index?
  if ( $selectedIndex | is-empty ) {
    return
  }

  $map_list | filter {|it| 
    ($it.index == $selectedIndex)
  } | get 0 |get value
}

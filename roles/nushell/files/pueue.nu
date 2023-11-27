def parse-status [ value ] {
  print $value
  try {
    return $"Failed: ($value.Done.Failed) ->"
  }
  try {
    return ($value.Done + " ->")
  }
  return ($value + " ->")
}
def complete-jobs [ ] {
  pueue status --json|from json|get tasks|values|each { {value: $in.id , description: $"(parse-status $in.status) ($in.command)" } }
}

def complete-groups [ ] {
  pueue status --json|from json|get groups|items {|key, value| $key}
}

def "job follow" [ id: string@complete-jobs ] {
  pueue follow $id
}

def "job kill" [ id: string@complete-jobs ] {
  pueue kill $id
}

def "job wait" [ id: string@complete-jobs ] {
  pueue wait $id
}

def "job clean" [ gid?: string@complete-groups ] {
  if ($gid|is-empty) {
    pueue clean
  } else {
    pueue clean -g $gid
  }
}


def "job add" [ command: any, --gid: string@complete-groups ] {
  mut source_code = ""
  let type = $command|describe
  if ($type == closure) {
    $source_code = (view source $command | str trim -l -c '{' | str trim -r -c '}')
  } else if ($type == string ) {
    $source_code = $command
  } else {
    return (echo "Invalid command type: $type")
  }

  let source_code =   if ($gid|is-empty) {
    return (pueue add -p -i -- $source_code)
  } else {
    return (pueue add -g $gid -p -i -- $source_code)
  }
}

def job [ ] {
  pueue status
}

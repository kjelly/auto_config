let path_candidates = [
  ($env.HOME | path join bin)
  ($env.HOME | path join mybin)
  ($env.HOME | path join dark-sdk bin)
  ($env.HOME | path join .cargo bin)
  ($env.HOME | path join .local bin)
  ($env.HOME | path join .deno bin)
  ($env.HOME | path join .asdf shims)
  ($env.HOME | path join .asdf bin)
  "/home/linuxbrew/.linuxbrew/bin"
  "/snap/bin"
]

let extra_paths = (
  $path_candidates
  | each {|pattern| glob $pattern }
  | flatten
  | where {|path| ($path | path type) == dir }
)

$env.PATH = ($extra_paths | prepend $env.PATH | uniq)

$env.config = ($env.config | upsert show_banner false)
$env.config = ($env.config | upsert edit_mode vi)
$env.EDITOR = nvim
alias vim = nvim
alias in = enter
alias cd1 = cd ..
alias cd2 = cd ../../
alias cd3 = cd ../../../
alias cd4 = cd ../../../../
alias cd5 = cd ../../../../../
alias z1 = cd ..
alias z2 = cd ../../
alias z3 = cd ../../../
alias z4 = cd ../../../../
alias z5 = cd ../../../../../

$env.config = ($env.config | merge {
  history: {
    file_format: "sqlite"
    isolation: true
    sync_on_enter: false
  }
})

$env.config.hooks.env_change.cloud = [
      { |before, after|
        if ( $env.cloud == 1 ) {
            $env.PROMPT_COMMAND = { || create_left_prompt }
        }
      }
]

def update-z [ path ] {
  ls -f $path | where type == dir | par-each { |it|
    let name = (readlink -f $it.name)
    if (zoxide query $name | str contains $name ) {
      echo $"($name) exists"
    } else {
      zoxide add $name
      echo $"Adding ($name)"
    }
  }
}
def vim [...file: string] {
  let af = ($file | each {|f|
            if ($f|str substring ..1) in ['/', '~'] {
                $f | path expand
            } else {
                $"($env.PWD)/($f)"
            }
        })

  mut editor = "vim"
  if ((which nvim |length ) > 0) {
    $editor = "nvim"
  }
  if ( $editor == "nvim" ) {
    if ( $env.IN_VIM? == null ) {
      nvim ...$af
    } else {
      let action = "edit"
      let cmd = $"<cmd>($action) ($af|str join ' ')<cr>"
      nvim --headless --noplugin --server $env.NVIM --remote-send $cmd
    }
  } else {
    /usr/bin/vim ...$af
  }
}

def fzf [ ] {
  let stdin = $in
  let a = ($stdin | detect columns)
  let start = (if ( $a | is-empty ) {
    $stdin
  } else {
    $a
  })
  let userSelect = (($start | par-each -t 8 {|it| $it|to nuon }|str join "\n" |^fzf) | str trim)
  echo $userSelect
  $userSelect | from nuon
}

def "z-complete" [ context: string ] {
  let pattern = ($context | split row ' '| drop nth 0)
  mut lst = (zoxide query -l ...$pattern |lines|first 15 )
  $lst = ($lst | append (zoxide query -l ($context | split words | last) |lines|first 15  ))
  let len = ($pattern | length)
  if ( $len == 0) {
    $lst = ($lst | append (ls -f $env.PWD|where type == directory|get name )) 
  }
  if ( $len == 1) {
    try {
      $lst = ($lst | append (ls -f $"($pattern|get 0)*" |where type == dir |get name ))
    } catch {
    }
  }
  $lst | uniq
}

def --env z [ arg0?:string@"z-complete", ...rest:string ] {
  if ($arg0 == null ) {
    cd
    return
  }
  let path = if (($rest | length) <= 2) and ($arg0 == '-' or ($arg0 | path expand | path type) == dir) {
    $arg0
  } else {
    (zoxide query --exclude $env.PWD -- $arg0 ...$rest | str trim -r -c "\n")
  }
  cd $path
}

def --env zi [...rest:string] {
  cd $'(zoxide query --interactive -- ...$rest | str trim -r -c "\n")'
}

def my-prompt [ ] {
  try {
    return (starship prompt)
  } catch {}
  try {
    return ([$"(hostname) (pwd)"] | str join)
  } catch {}
}

$env.PROMPT_COMMAND = {|| ([(my-prompt) $env.note? "\n" ->] | str join ' ') }
$env.PROMPT_COMMAND_RIGHT = ""

use kubernetes.nu *
use docker.nu *
use nvim.nu *

$env.config = ($env.config | upsert keybindings ( $env.config.keybindings | append [
  { name: custom modifier: alt keycode: char_h mode: [emacs vi_normal vi_insert]  event: { until: [
    { send: menuprevious }
    { send: Left }
  ]}}
  { name: custom modifier: alt keycode: char_l mode: [emacs vi_normal vi_insert]  event: {  until: [
    { send: menunext }
    { send: Right }
  ] } }
  { name: custom modifier: alt keycode: char_j mode: [emacs vi_normal vi_insert]  event: { until: [
    { send: menudown }
    { send: menu name: completion_menu }
  ]}}
  { name: custom modifier: alt keycode: char_k mode: [emacs vi_normal vi_insert]  event: { until: [
    { send: menuup }
  ]}}
  { name: custom modifier:control keycode: char_f mode: [emacs vi_normal vi_insert]  event: { send: HistoryHintComplete } }
  { name: custom modifier:alt keycode: char_f mode: [emacs vi_normal vi_insert]  event: { send: HistoryHintWordComplete } }
  { name: custom modifier:alt keycode: char_q mode: [emacs vi_normal vi_insert]  event: [{edit: Clear}, {edit: InsertString, value: "workspace"}, {send: Enter}] }
]))


def h [ pattern ] {
  help commands | where name =~ $pattern or category =~ $pattern
}

source ~/.config/custom.nu

$env.config.hooks.env_change.PWD = ($env.config.hooks.env_change.PWD | append [
        {
            condition: {|before, after|
                ($after | path join local.nu | path exists)
            }
            code: "overlay use --reload local.nu"
        }
    ]
)

$env.config = ($env.config | upsert keybindings ( $env.config.keybindings | append [{
    name: fuzzy_module
    modifier: alt
    keycode: Enter
    mode: [emacs, vi_normal, vi_insert]
    event: {
        send: executehostcommand
        cmd: '
            let cmd = (commandline)
            if ( $cmd | is-empty ) {
            } else {
              commandline -r $"tmux new-window -b -c (pwd) ($cmd)"
            }
        '
    }
}] ))

$env.config = ($env.config | upsert keybindings ( $env.config.keybindings | append [{
    name: fuzzy_module
    modifier: shift_alt
    keycode: Enter
    mode: [emacs, vi_normal, vi_insert]
    event: {
        send: executehostcommand
        cmd: '
            let cmd = (commandline)
            if ( $cmd | is-empty ) {
            } else {
              commandline -r $"pueue follow \(pueue add -p -- ($cmd)\)"
            }
        '
    }
}] ))

$env.config = ($env.config | upsert keybindings ( $env.config.keybindings | append [{
    name: fuzzy_module
    modifier: alt
    keycode: char_m
    mode: [emacs, vi_normal, vi_insert]
    event: {
        send: executehostcommand
        cmd: '
            commandline --replace "use "
            commandline --insert (
                $env.NU_LIB_DIRS
                | each {|dir|
                    ls ($dir | path join "**" "*.nu")
                    | get name
                    | str replace $dir ""
                }
                | flatten
                | input list --fuzzy
                    $"Please choose a (ansi magenta)module(ansi reset) to (ansi cyan_underline)load(ansi reset):"
                )
        '
    }
}] ))

$env.config.color_config = {
    separator: blue_bold
    leading_trailing_space_bg: { attr: n } # no fg, no bg, attr none effectively turns this off
    header: green_bold
    empty: blue
    bool: {|| if $in { 'dark_cyan' } else { 'cyan' } }
    int: cyan
    filesize: {|e|
        if $e == 0b {
            'cyan'
        } else if $e < 1mb {
            'cyan_bold'
        } else { 'blue_bold' }
    }
    duration: cyan
    date: {|| (date now) - $in |
        if $in < 1hr {
            'purple'
        } else if $in < 6hr {
            'red'
        } else if $in < 1day {
            'yellow'
        } else if $in < 3day {
            'green'
        } else if $in < 1wk {
            'light_green'
        } else if $in < 6wk {
            'cyan'
        } else if $in < 52wk {
            'blue'
        } else { 'cyan' }
    }
    range: cyan
    float: cyan
    string: cyan
    nothing: cyan
    binary: cyan
    cellpath: cyan
    row_index: green_bold
    record: yellow_bold
    list: yellow_bold
    block: yellow_bold
    hints: cyan
    search_result: {fg: yellow_bold bg: red}    
    shape_and: purple_bold
    shape_binary: purple_bold
    shape_block: blue_bold
    shape_bool: light_cyan
    shape_closure: green_bold
    shape_custom: green
    shape_datetime: cyan_bold
    shape_directory: cyan
    shape_external: cyan
    shape_externalarg: green_bold
    shape_filepath: cyan
    shape_flag: blue_bold
    shape_float: purple_bold
    shape_garbage: { fg: yellow_bold bg: red attr: b}
    shape_globpattern: cyan_bold
    shape_int: purple_bold
    shape_internalcall: cyan_bold
    shape_list: cyan_bold
    shape_literal: blue
    shape_match_pattern: green
    shape_matching_brackets: { attr: u }
    shape_nothing: light_cyan
    shape_operator: yellow
    shape_or: purple_bold
    shape_pipe: purple_bold
    shape_range: yellow_bold
    shape_record: cyan_bold
    shape_redirection: purple_bold
    shape_signature: green_bold
    shape_string: green
    shape_string_interpolation: cyan_bold
    shape_table: blue_bold
    shape_variable: purple
    shape_vardecl: purple
}

def m [ cmd ] {
  [$"https://raw.githubusercontent.com/tldr-pages/tldr/main/pages/linux/($cmd).md",
   $"https://raw.githubusercontent.com/tldr-pages/tldr/main/pages/common/($cmd).md"] | par-each -t 2 {|it| try { http get $it } }
}

let repo_list = ["nushell/nushell", "casey/just", "ajeetdsouza/zoxide", "Ryooooooga/croque",
 "denoland/deno", "Nukesor/pueue", "ellie/atuin", "ducaale/xh", "YesSeri/xny-cli", "denisidoro/navi",
 "orhun/halp", "starship/starship", "sharkdp/bat", "sharkdp/fd", "sharkdp/lscolors",
 "BurntSushi/ripgrep", "xo/usql", "ogham/dog", "derailed/k9s", "ahmetb/kubectx", "helm/helm",
 "rclone/rclone", "restic/restic", "kopia/kopia", "Genivia/ugrep", "junegunn/fzf", "open-policy-agent/conftest",
 "jqlang/jq", "tomnomnom/gron", "zyedidia/micro", "helix-editor/helix", "kovidgoyal/kitty", "tmux/tmux",
 "theryangeary/choose", "direnv/direnv", "loft-sh/devpod", "tsl0922/ttyd", "aristocratos/btop", "moncho/dry",
 "xxxserxxx/gotop", "orhun/kmon", "browsh-org/browsh", "mrusme/planor", "jesseduffield/lazydocker",
 "tsenart/vegeta", "nicolas-van/multirun", "rsteube/carapace-bin", "urbanogilson/lineselect",
 "ast-grep/ast-grep", "jirutka/tty-copy", "theimpostor/osc", "d-kuro/kubectl-fuzzy",
 "nektos/act",
]

def repo [ ] {
  $repo_list | append ($repo_list|each {|it| $it|split row '/'|last })
}

def real_repo [ repo ] {
  let repo = ($repo | str replace 'https://github.com/' '')
  if ($repo | str contains '/') {
    $repo
  } else {
    $repo_list | filter {|it| ($it|split row '/'|last) == $repo } | get 0
  }
}

def github-link [context: string] {
  let rows = ($context | str trim|split row ' ')
  let repo = (if (($rows|length) == 3) { $rows|get 1 } else { $rows | last })
  # let repo = ($repo | str replace 'https://github.com/' '')
  let repo = (real_repo $repo)
  mut links = (http get $"https://api.github.com/repos/($repo)/releases/latest"|get assets |get browser_download_url)
  mut archs = [(uname -m)]
  if (($archs|get 0) == "x86_64") {
    $archs = ($archs | append ["amd64" "x64"])
  }
  let $archs = $archs
  let filtered = ($links|filter {|it| $it|str contains -i (uname) })
  if (not ($filtered|is-empty)) {
    $links = $filtered
  }
  let filtered = ($links|filter {|it| ($archs | each {|a| $it|str contains -i $a}|any {|it| $it}) })
  if (not ($filtered|is-empty)) {
    $links = $filtered
  }
  $links
}

def download-github [ repo: string@repo, link: string@github-link ] {
  # let repo = ($repo | str replace 'https://github.com/' '')
  let repo = (real_repo $repo)
  let name = (http get $"https://api.github.com/repos/($repo)/releases/latest"|get assets |filter {$in.browser_download_url == $link } |get name|get 0)
  wget $link -O $name
  mkdir /tmp/aa
  if ( $name | str ends-with '.gz' ) {
    tar zxvf $name -C /tmp/aa
  } else if ( $name | str ends-with '.zip' ) {
    unzip $name -d /tmp/aa
  } else if ( $name | str ends-with '.tar') {
    tar xvf $name -C /tmp/aa
  } else if ( $name | str ends-with '.xz') {
    tar xvf $name -C /tmp/aa
  } else if ( $name | str ends-with '.deb') {
    sudo dpkg -i $name
    return
  } else {
    chmod +x $name
    let new = ($name|str replace -a - _|split column -c _ name|get 0.name)
    mv $name $"/tmp/aa/($new)"
  }
  ^find /tmp/aa/ -type f -executable|lines|each {|it| cp $it ~/bin/ }
}

def github-readme [ repo ] {
  let repo = ($repo | str replace 'https://github.com/' '')
  http get $"https://raw.githubusercontent.com/($repo)/master/README.md" | glow
}

def retry [ count:int, block:closure ] {
  mut _count = $count
  mut out = {}
  while $_count > 0 {
    $_count = $_count - 1
    let c = $_count
    try {
      return {
        "result": (do $block),
        "retries": ($count - $c - 1),
        "error": null
      }
    } catch {
      if $c == 0 {
        return {
          "result": null,
          "retries": ($count - $c),
          "error": $in.debug
        }
      }
    }
  }
}

bash -c $"source ($env.HOME)/.profile && env"
    | lines
    | parse "{n}={v}"
    | filter { |x| ($x.n not-in $env) or $x.v != ($env | get $x.n) }
    | where n not-in ["_", "LAST_EXIT_CODE", "DIRS_POSITION"]
    | transpose --header-row
    | into record
    | load-env

def contains [lst ele] {
  $lst | each {|it| $it == $ele}|reduce {|a, b| $a or $b}
}

def list-diff [a b] {
  $a | filter {|it| not (contains $b $it) }
}

let carapace_completer = {|spans|
    carapace $spans.0 nushell ...$spans | from json
}

let fish_completer = {|spans|
    fish --command $'complete "--do-complete=($spans | str join " ")"'
    | $"value(char tab)description(char newline)" + $in
    | from tsv --flexible --no-infer
}

let zoxide_completer = {|spans|
    $spans | skip 1 | zoxide query -l $in | lines | where {|x| $x != $env.PWD}
}

let fish_with_carapace_completer = {|spans|
  [
    (
      carapace $spans.0 nushell ...$spans | from json
    ),
    (
      fish --command $'complete "--do-complete=($spans | str join " ")"'
      | $"value(char tab)description(char newline)" + $in
      | from tsv --flexible --no-infer
    )

  ] | flatten | each {|it| $it | str trim } | uniq
}

let external_completer = {|spans|
    match $spans.0 {
        nu => $fish_completer
        git => $fish_completer
        asdf => $fish_completer
        z => $zoxide_completer
        zi => $zoxide_completer
        _ => $carapace_completer
    } | do $in $spans
}

$env.config = ($env.config | upsert completions  {
    case_sensitive: false
    quick: true
    partial: true
    algorithm: "fuzzy"
    external: {
      enable: true
      max_results: 100
      completer: $fish_with_carapace_completer
    }
})

def auto [ --strip (-s) ] {
  let input = $in
  mut data = null
  try {
    $data = (echo $input|from json)
  } catch {
  }
  if ($data == null ) {
    try {
      $data = (echo $input|from yaml)
    } catch {
    }
  }
  if ($data == null) {
    return $input
  } else {
    if (not $strip) {
      return $data
    }
    try {
      mut values = (echo $data|values)
      if (($values|length) == 1) {
        return ($values|first)
      }
    }
    let lst = ([ ] | append $data)
    if (($lst|length) == 1) {
      return ($lst|first)
    }
    return $data
  }
  return $input
}

$env.config.hooks.env_change.PWD = ($env.config.hooks.env_change.PWD | append [
        {
            code: "
              if (not (which direnv | is-empty)) {
                let direnv = (direnv export json | from json)
                let direnv = if not ($direnv | is-empty) { $direnv } else { {} }
                $direnv | load-env
              }
              if (not (which zoxide | is-empty)) {
                zoxide add -- $env.PWD
              }

            "
        }
])

$env._out = []
$env.config.hooks.display_output = {
  let stdin  = $in
  try {
    if (($stdin|get out?) == "out") {
      $stdin |get stdout | if (term size).columns >= 100 { table -e } else { table }
    }
  } catch {

  }
  $env._out = ($env._out | prepend [$stdin] | uniq)
  let l = ($env._out | length)
  if ( $l > 10) {
    $env._out = ($env._out | first 10)
  }
  $stdin | if (term size).columns >= 100 { table -e } else { table }
}

def out [ index?: int ] {
  let stdin = $in
  if ($index == null) {
    return {
      out: out
      stdout: $env._out
    }
  } else {
    try {
      return ($env._out | get ($index - 1))
    } catch {
      return {
        out: out
        stdout: null
      }
    }
  }
}

$env.reg = { }
def --env reg [ name?: string ] {
  let stdin = $in
  if ($name == null ) {
    return $env.reg
  } else {
    if ($stdin == null) {
      return ($env.reg | get $name)
    } else {
      $env.reg = ($env.reg | upsert $name $stdin)
      return $stdin
    }
  }
}

export def r-nu [ host: string, command:string ] {
  let code = $in
  $code | ssh -t $host tee /tmp/tmp.nu
  ssh $host nu --config /tmp/tmp.nu -c $command
}

$env.config.hooks.pre_execution = ($env.config.hooks.pre_execution | append [
        {
            code: '
              print $"(ansi title)(pwd)> (history | last | get command)(ansi st)"
            '
        }
])
$env.config.hooks.pre_prompt = ($env.config.hooks.pre_prompt | append [
        {
            code: '
              print $"(ansi title)(pwd)> nu (ansi st)"
            '
        }
])

export def --wrapped tr [ ...args ] {
  let path = (pwd)
  tmux new-window -b -c $path direnv exec $path bash -c $'"($command)"'
}

def "nu-complete just" [] {
    (^just --dump --unstable --dump-format json | from json).recipes | transpose recipe data | flatten | where {|row| $row.private == false } | select recipe doc parameters | rename value description
}

# Just: A Command Runner
export extern "just" [
    ...recipe: string@"nu-complete just", # Recipe(s) to run, may be with argument(s)
]

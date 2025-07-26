mut $new_config = $env.config
$new_config.show_banner = false
$new_config.cursor_shape.emacs = "block"
$new_config.edit_mode = "emacs"

$env.EDITOR = "nvim"
$env.SHELL = "nu"

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

use std-rfc *;
use std *;

$new_config = ($new_config | merge {
  history: {
    file_format: "sqlite"
    isolation: true
    sync_on_enter: false
  }
})

$new_config.hooks.env_change.cloud = [
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

def --env update-eink-env [ width?, --auto ] {
  try {
    if ($width != null) { tmux set-environment -g EINK_WIDTH $width }
    if ($auto) { tmux set-environment -g EINK_WIDTH (tput cols) }
    $env.EINK_WIDTH = (tmux show-environment -g EINK_WIDTH|str replace "EINK_WIDTH=" "")
  } catch {}
}

def vim [...file: string] {
  update-eink-env
  let af = ($file | each {|f| $f | path expand })

  mut editor = "vim"
  if ((which nvim |length ) > 0) {
    $editor = "nvim"
  }
  if ( $editor == "nvim" ) {
    if ( $env.IN_VIM? == null ) {
      let file_list = ["pyproject.toml", ""]
      let command_dict = {
        "pyproject.toml": ["poetry", "run"]
        "": []
      }
      for i in ($command_dict | items {|a, b| $a}) {
        try {
          if ($i != "") and ($i | path exists | not $in) {
            continue
          }
          let cmds = (($command_dict | get $i)|append [firejail  --noprofile --caps.drop=all --nonewprivs --seccomp --noroot --disable-mnt $"--read-only=($env.HOME)" $"--read-write=($env.HOME)/.local/state/nvim" $"--read-write=./*" $"--read-write=($env.HOME)/.config/nvim" $"--read-write=($env.HOME)/.vim_cache" ...($af|each {|it| $"--read-write=($it)"}) --appimage /usr/local/bin/nvim ...$af])
          let cmds = (($command_dict | get $i)|append [nvim  ...$af])
          run-external ($cmds | first) ...($cmds | skip 1)
          # firejail  --noprofile --caps.drop=all --nonewprivs --seccomp --noroot --disable-mnt --appimage /usr/local/bin/nvim ...$cmd ...$af
          break
        } catch {
        }
      }
    } else {
      let action = "edit"
      let cmd = $"<cmd>($action) ($af|str join ' ')<cr>"
      nvim --headless --noplugin --server $env.NVIM --remote-send $cmd
    }
  } else {
    /usr/bin/vim ...$af
  }
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

def --env z [...rest:string] {
  let lst = (zoxide query -l -- ...$rest|lines)
  if ($lst | is-empty) {
    print "not found"
    return
  }
  if ($lst | length) == 1 {
    cd ($lst | get 0)
    return
  }
  cd $'($lst|input list --fuzzy | str trim -r -c "\n")'
}

def --env zl [ ] {
  cd (zoxide query -l|lines|where {|it| $it starts-with $"(pwd)/"}|each {|it| $it | str replace (pwd) '.'}|input list --fuzzy)
}

def --env gg [ ] {
  mut p = (pwd)
  while ($p != "/") {
    if ($p | path join ".git"|path exists) {
      break
    }
    $p = ($p | path join ".."|path expand)
  }
  if ($p != "/") {
    cd $p
  }
}

def my-prompt [ ] {
  try {
    return (starship prompt)
  } catch {}
  try {
    return ([$"(hostname) (pwd)"] | str join)
  } catch {}
}

$env.PROMPT_COMMAND = {|| ([(my-prompt) $"($env.note?) " "\n" ->] | str join ' ') }
$env.PROMPT_COMMAND_RIGHT = ""

$new_config = ($new_config | upsert keybindings ( $new_config.keybindings | append [
  { name: custom modifier: alt keycode: char_n mode: [emacs vi_normal vi_insert]  event: { until: [
    { send: menunext }
    { send: Down }
  ]}}
  { name: custom modifier: alt keycode: char_p mode: [emacs vi_normal vi_insert]  event: { until: [
    { send: menuprevious }
    { send: Up }
  ]}}
  {
        name: another_esc_command
        modifier: control
        keycode: char_s
        mode: [emacs, vi_normal, vi_insert]
        event: { until: [
            {
              send: menu
              name: ide_completion_menu
            }
            { send: esc }
        ]}
  }
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
  { name: custom modifier:alt keycode: char_q mode: [emacs vi_normal vi_insert]  event: [{edit: Clear}, {edit: InsertString, value: "workspace"}, {send: Enter}] }
  {
      name: "Run zoxide"
      modifier: Alt
      keycode: char_c
      mode: [emacs, vi_normal, vi_insert]
      event: {
        send: executehostcommand,
        cmd: "zl"
      }
  }

]))

$new_config.menus = ($env.config.menus? | default [ ] | append [
        {
            name: ide_completion_menu
            only_buffer_difference: false
            marker: "| "
            type: {
                layout: ide
                min_completion_width: 0,
                max_completion_width: 150,
                max_completion_height: 110,
                padding: 0,
                border: true,
                cursor_offset: 0,
                description_mode: "right"
                min_description_width: 0
                max_description_width: 150
                max_description_height: 110
                description_offset: 1
                correct_cursor_pos: true
            }
            style: {
                text: green
                selected_text: { attr: r }
                description_text: yellow
                match_text: { attr: u }
                selected_match_text: { attr: ur }
            }
        }
])


def h [ pattern ] {
  help commands | where name =~ $pattern or category =~ $pattern
}

source ~/.config/custom.nu

$new_config.hooks.env_change.PWD = ([ ] | append [
        {
            condition: {|before, after|
                ($after | path join local.nu | path exists)
            }
            code: "overlay use --reload local.nu"
        }
        {
            code: "
              if (not (which direnv | is-empty)) {
                if ("auto-direnv"|path exists) {direnv allow .}
                let direnv = (direnv export json | from json)
                let direnv = if not ($direnv | is-empty) { $direnv } else { {} }
                $direnv | load-env
              }
              if (not (which zoxide | is-empty)) {
                zoxide add -- $env.PWD
              }

            "
        }
    ]
)

$new_config = ($new_config | upsert keybindings ( $new_config.keybindings | append [{
    name: "run the command in systemd"
    modifier: alt
    keycode: Enter
    mode: [emacs, vi_normal, vi_insert]
    event: {
        send: executehostcommand
        cmd: '
            let cmd = (commandline)
            if ( $cmd | is-empty ) {
            } else {
              commandline edit -r $"run ($cmd)"
            }
        '
    }
}] ))

$new_config = ($new_config | upsert keybindings ( $new_config.keybindings | append [{
    name: "run the command in pueue"
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

$new_config = ($new_config | upsert keybindings ( $new_config.keybindings | append [{
    name: "run the command in pueue"
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


$new_config = ($new_config | upsert keybindings ( $new_config.keybindings | append [{
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
 "nektos/act", "FiloSottile/age", "marcosnils/bin", "twpayne/chezmoi", "bitrise-io/envman", "guyfedwards/nom", "joshmedeski/sesh"
 "itchyny/bed", "ddanier/nur", "https://github.com/dbrgn/tealdeer", "dundee/gdu", "tstack/lnav", "stern/stern",
 "pouriyajamshidi/tcping", "sharkdp/hyperfine", "pvolok/mprocs"

]

def repo [ ] {
  $repo_list | append ($repo_list|each {|it| $it|split row '/'|last })
}

def real_repo [ repo ] {
  let repo = ($repo | str replace 'https://github.com/' '')
  if ($repo | str contains '/') {
    $repo
  } else {
    $repo_list | where {|it| ($it|split row '/'|last) == $repo } | get 0
  }
}

def github-link [context: string] {
  let rows = ($context | str trim|split row ' ')
  let repo = (if (($rows|length) == 3) { $rows|get 1 } else { $rows | last })
  let repo = (real_repo $repo)
  mut links = (http get $"https://api.github.com/repos/($repo)/releases/latest"|get assets |get browser_download_url)
  mut archs = [(^uname -m)]
  if (($archs|get 0) == "x86_64") {
    $archs = ($archs | append ["amd64" "x64"])
  }
  let $archs = $archs
  let filtered = ($links|where {|it| $it|str contains -i (^uname) })
  if (not ($filtered|is-empty)) {
    $links = $filtered
  }
  let filtered = ($links|where {|it| ($archs | each {|a| $it|str contains -i $a}|any {|it| $it}) })
  if (not ($filtered|is-empty)) {
    $links = $filtered
  }
  $links
}

def download-github [ repo: string@repo ] {
  let tmpdir = (mktemp -t -d download-github.XXXXX)
  cd $tmpdir
  let repo = (real_repo $repo)
  let link_list = (github-link $repo | where {|it| $it !~ '.*sha256'} )
  let link = ($link_list | get ($link_list | each {|it| $it |split row '/' | last} | input list --fuzzy --index)|str trim)

  let name = (http get $"https://api.github.com/repos/($repo)/releases/latest"|get assets |where {$in.browser_download_url == $link } |get name|get 0)
  wget $link -O $name
  rm -rf /tmp/aa
  mkdir /tmp/aa
  if ( $name | str ends-with '.gz' ) {
    tar zxvf $name -C /tmp/aa
  } else if ( $name | str ends-with '.tgz' ) {
    tar zxvf $name -C /tmp/aa
  } else if ( $name | str ends-with '.zip' ) {
    unzip $name -d /tmp/aa
  } else if ( $name | str ends-with '.tar.bz2') {
    tar xvf $name -C /tmp/aa
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

def download-link [ link: string ] {
  rm /tmp/a
  mkdir /tmp/a
  mkdir /tmp/a/a
  cd /tmp/a
  wget $link
  let name = (ls | get 0.name)
  if ( $name | str ends-with 'tar.gz' ) {
    tar zxvf $name -C /tmp/aa
  } else if ( $name | str ends-with '.zip' ) {
    unzip $name -d /tmp/aa
  } else if ( $name | str ends-with '.tar') {
    tar xvf $name -C /tmp/aa
  } else if ( $name | str ends-with '.xz') {
    tar xvf $name -C /tmp/aa
  } else if ( $name | str ends-with '.gz' ) {
    mv $name aa/
    gzip -d $name
    chmod +x aa/*
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
    | where { |x| ($x.n not-in $env) or $x.v != ($env | get $x.n) }
    | where n not-in ["_", "LAST_EXIT_CODE", "DIRS_POSITION"]
    | transpose --header-row
    | into record
    | load-env

def contains [lst ele] {
  $lst | each {|it| $it == $ele}|reduce {|a, b| $a or $b}
}

def list-diff [a b] {
  $a | where {|it| not (contains $b $it) }
}

let carapace_completer = {|spans|
  # if the current command is an alias, get it's expansion
  let expanded_alias = (scope aliases | where name == $spans.0 | get -i 0 | get -i expansion)

  # overwrite
  let spans = (if $expanded_alias != null  {
    # put the first word of the expanded alias first in the span
    $spans | skip 1 | prepend ($expanded_alias | split row " " | take 1)
  } else {
    $spans
  })

  let ret = (carapace $spans.0 nushell ...$spans
  | from json)
  if ($ret | is-empty) {
    carapace ls nushell ...($spans | skip 1) | from json
  } else {
    $ret
  }
  $ret
}


let fish_completer = {|spans|
  if (which fish|is-empty) {
    return null
  }
  fish --command $'complete "--do-complete=($spans | str join " ")"'
  | $"value(char tab)description(char newline)" + $in
  | from tsv --flexible --no-infer
}

let zoxide_completer = {|spans|
    $spans | skip 1 | zoxide query -l $in | lines | where {|x| $x != $env.PWD}
}

let fish_with_carapace_completer = {|spans|
  let ret = ([{||
    if (which carapace | is-not-empty ) {
        carapace $spans.0 nushell ...$spans | from json
    } else {
      [ ]
    }
  },
  {||
    if (which argc | is-not-empty ) {
      argc --argc-compgen nushell "" ...$spans
      | split row "\n" | slice 0..-2
      | each { |line| $line | split column "\t" value description } | flatten
    } else {
      [ ]
    }
  }
  {||
    do $fish_completer $spans
  }
  ] | par-each -t 8 {|it| do -i $it } | flatten | each {|it| $it | str trim } |where {|it| $it != ""} | uniq)
  if ($ret | is-empty) {
    return null
  }
  $ret
}

let external_completer = {|spans|
    match $spans.0 {
        nu => $fish_completer
        git => $fish_completer
        vim => $fish_completer
        nvim => $fish_completer
        asdf => $fish_completer
        z => $zoxide_completer
        zi => $zoxide_completer
        _ => $carapace_completer
    } | do $in $spans
}

$new_config = ($new_config | upsert completions  {
    case_sensitive: false
    quick: true
    partial: true
    algorithm: "fuzzy"
    external: {
        enable: false
        completer: $fish_completer
    }
})

if (which carapace | is-not-empty) {
  $new_config.completions.external = {
    enable: true
    completer: $carapace_completer
  }
} else if (which fish | is-not-empty) {
  $new_config.completions.external = {
    enable: true
    completer: $fish_completer
  }
}

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

def --env update-nushell-theme [ ] {
  let columns = ((term size) | get columns)
  if ($env.previous_columns? | default "0") != columns {
    let EINK_WIDTH = (try {tmux show-environment -g EINK_WIDTH|str replace "EINK_WIDTH=" ""} catch {})
    use std;
    if $columns  == $EINK_WIDTH {
      $env.config.color_config = (std config light-theme | upsert hint "dark_gray_bold")
    } else {
      $env.config.color_config = (std config dark-theme | upsert hints cyan)
    }
    $env.previous_columns = $columns
  }
}

$env._out = []
$new_config.hooks.display_output = {
  let stdin  = $in

  update-nushell-theme
  #
  # try {
  #   if (($stdin|get out?) == "out") {
  #     $stdin |get stdout | if (term size).columns >= 100 { table -e } else { table }
  #   }
  # } catch {
  #
  # }
  # $env._out = ($env._out | prepend [$stdin] | uniq)
  # let l = ($env._out | length)
  # if ( $l > 10) {
  #   $env._out = ($env._out | first 10)
  # }
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

# $new_config.hooks.pre_execution = ($new_config.hooks.pre_execution | append [
#         {
#             code: '
#               print $"(ansi title)(pwd)> (history | last | get command)(ansi st)"
#             '
#         }
# ])
# $new_config.hooks.pre_prompt = ($new_config.hooks.pre_prompt | append [
#         {
#             code: '
#               print $"(ansi title)(pwd)> nu (ansi st)"
#             '
#         }
# ])

export def --wrapped tr [ ...command] {
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


def notica [ text:string ] {
  curl --data $"d:($text)" $"https://notica.us/($env.notica_key?)" ;
}

$env.max_jobs = 9

def --wrapped "run" [ --doc="", ...command ] {
  mut desc = ($command | str join ' ')
  if ($doc != "") {
    $desc = $doc
  }
  let _unit = (not-used-units|first)
  mut _command = $command
  if (echo 'local.nu' | path exists) {
    $_command = ($_command | prepend "source local.nu;\n")
  }
  mut binary = ["nu"]
  if (which direnv|is-not-empty) {
    $binary = ($binary | prepend ["direnv", "exec", "."])
  }

  systemd-run --user -u $_unit --service-type=oneshot -d --no-block --description $desc ...$binary -c ($_command | str join ' ')
  $_unit
}

def not-used-units [ ] {
  let running_unit_names = (all-unit-info|where {|it|
    $it.ExecStart? != null
  }|get Id|each {|it| $it|str replace '.service' ''})
  all-unit-name |where {|it| $it not-in $running_unit_names}
}

def note [ -t="infinity", --after (-a): string="", text ] {
  let _unit = (not-used-units|first)
  mut extra = []
  if ($after != "") {
    $extra = [--on-active $after]
  }
  systemd-run --user -u $_unit --service-type=oneshot -d --no-block --description $"📓($text)" -G ...$extra sleep $t

}

def log [ $unit?:string@all-unit-name , --follow (-f)] {
  let stdin = $in
  mut extra = [ ]
  mut _unit = $unit
  if ($follow or $_unit == null ) {
    $extra = ($extra | append ["-f", "--since=now", "--output=cat"])
    if ($_unit == null) {
      $_unit = $stdin
    }
    if ($env.IN_VIM? == "1") {
      $extra = ($extra | append ["--no-pager"])
    }
    journalctl --user -u $_unit -e --no-hostname ...$extra

  } else {
    journalctl --user -u $_unit --no-hostname -r --no-pager|lines|take until {|it| ('systemd' in $it and 'Starting' in $it)}|reverse | str join "\n"
  }
}

def all-log [ -n:int=5 ] {
  all-unit-name | par-each -t 4 {|it| {name: $it, log: (log $it|lines|first 5|str join "\n")} }|sort-by name
}

def show [ unit:string@running-units-complete ] {
  systemctl --user status $unit
}

def get-systemd-info [ unit: string ] {
  systemctl --user show $unit|lines|each {|it| split row '=' -n 2|{ $in.0 : $in.1 }}|reduce {|a, b| $a | merge $b}
}

def stop [ ...units:string@running-units-complete ] {
  $units | par-each -t 2 {|unit|
    if (systemctl --user show $unit|find 'ActiveState=inactive'|is-not-empty) {
      systemctl --user stop $"($unit|str replace '.service' '').timer"
    } else  if (systemctl --user show $unit|find 'ActiveState=failed'|is-not-empty) {
      systemctl --user reset-failed $unit
    } else {
      systemctl --user stop $unit
    }
  }
  null
}

def clean [ ] {
  running-units | par-each {|it| stop $it.Id }
  running-units | par-each {|it| stop $it.Id }
  null
}

def all-unit-name [ ] {
  ["run"] | append (seq 1 ($env.max_jobs|into int)|each {|it| $"run($it)"})
}

def all-unit-info [ ] {
  all-unit-name | par-each -t 4 {|it| get-systemd-info $it}
}


def running-units [ ] {
  all-unit-info|where {|it|
    $it.ExecStart? != null
  } | sort-by Id
}

def running-units-complete [ ] {
  running-units | each {|it| {value: $in.Id , description: $in.Description}}
}

def bg-running [ ] {
  try {
    let icon_map = { activating: "🟢", inactive: "⏰", failed: "❌" }
    running-units | each {|it| $"[($it.Id|str replace '.service' ''|str replace 'run' ''):($icon_map | get -i $it.ActiveState)($it.Description)]"} | str join ' '|str trim
  } catch { "" }
}


def --wrapped sr [ ...command ] {
  let unit = $"sr-(date now | format date '%m%d-%H%M%S')"
  systemd-run --user -t -P -G ...$command
}

$new_config.keybindings = ($new_config.keybindings | where {|it| $it.name !~ "completion_menu"})
$new_config.keybindings = ($new_config.keybindings | append {
  name: completion_menu
  modifier: none
  keycode: tab
  mode: [emacs vi_normal vi_insert]
  event: {
      until: [
          { send: menu name: ide_completion_menu }
          { send: menunext }
          { edit: complete }
      ]
  }
})

if (($env.IN_VIM? == "1") and (which nvr | is-not-empty)) {
  $env.EDITOR = [nvr --remote-wait-silent -cc vsplit]
}

def "nu-complete t" [ ] {
  tmux list-sessions -F '#S'|lines
}
export extern t [ sessions:string@"nu-complete t" ]

def --wrapped bg [ ...command  ] {
  tmux new-window -c . -t popup: -d ...$command
}

def kaniko-build [ dockerfile: string, context: string, image: string, ...args:string  ] {
  let build_args = ($args | each {|it| ["--build-arg",  $it]}|flatten)
  let dct = {
    "apiVersion": "v1",
    "spec": {
      "containers": [
        {
          "name": "kaniko",
          "image": "gcr.io/kaniko-project/executor:latest",
          "stdin": true,
          "stdinOnce": true,
          "args": [
            "--dockerfile=Dockerfile",
            "--context=tar://stdin",
            "--cache-dir=/workspace/cache",
            $"--destination=($image)",
            ...$build_args
          ],
          "volumeMounts": [
            {
              "name": "docker-config",
              "mountPath": "/kaniko/.docker/"
            }
          ]
        }
      ],
      "volumes": [
        {
          "name": "docker-config",
          "configMap": {
            "name": "docker-config"
          }
        }
      ]
    }
  }
  tar zcvf - $context | kubectl run kaniko --rm --stdin=true --image=gcr.io/kaniko-project/executor:latest --restart=Never $"--overrides=($dct|to json --raw|str trim)"
}

def r [ task:string ] {
  let code = "import os\nos.system('nur " + $task + "')"
  python3 -c $code

}

def vimcopy [ ] { $in | tee { nvim - } }
$env.config = $new_config

def sops-age [ file, --key="~/.ssh/age-key.txt" ] {
  let key = ($env.SOPS_AGE_KEY_FILE | path expand )
  with-env {SOPS_AGE_KEY_FILE: $key} { sops edit --age (cat $key | grep public | split row ': '|last) $file }
}

def init-daytona-workspaces [ ] {
  docker ps --where ancestor=daytonaio/workspace-project:latest --format "{{.ID}}"|lines| each {|target|
    docker exec $target bash -c "sudo apt update;sudo apt install -y fuse3;touch ~/.config/custom.nu"
    docker cp ~/.config/nvim/ $"($target):/home/daytona/.config/"
    docker cp ~/.config/nushell/ $"($target):/home/daytona/.config/"
    docker cp ~/bin/nvim $"($target):/bin"
    docker cp ~/bin/nu $"($target):/bin"
  }
}

def age-edit [file, --key="simple"] {
  let tmp = $"/tmp/(random uuid)"
  age -d -i $"($env.HOME)/.ssh/($key)" $file | save -f $tmp
  nvim $tmp
  age -R $"($env.HOME)/.ssh/($key).pub" $tmp | save -f $file
}

def freeze-to-bg [ id ] {
  job spawn {|| job unfreeze $id}

}

def --env gm [ ] {
  git checkout (git remote show origin|lines|where {|it| $it =~ 'HEAD'}|get 0|split row ':'|get 1|str trim)
  git pull
}

def "complete act path" [ ] {
  gg
  ls $".github/workflows/"|get name
}

def --wrapped "act-wrapper" [ path?:string@"complete act path", ...args] {
  gg
  let all_file = (ls $".github/workflows/"|get name)
  let _path = ( if ($path == null) { (ls .github/workflows/|get name|input list --fuzzy) } else { ($all_file | where {|it| $it =~ $path}|get 0)})
  let args = ($args ++ ($env.act_args? | default []))
  print $args
  mut act_args = []
  act --container-options "--privileged -v /home/linuxbrew/:/home/linuxbrew/ -v /tmp/docker-cache/:/tmp/docker-cache/" -s $"SSH_KEY=(cat ~/.ssh/id_rsa|base64 -w 0)" ...$act_args --detect-event -W $_path --insecure-secrets ...$args
}

def allow-direnv [ ] {
  direnv allow .
  exec nu
}

def wait-for-ready [ code ] {
  loop {
    let result = (do $code | complete)
    if ($result.exit_code == 0) {
      return
    }
    sleep 1sec
  }
}

def wait-or-timeout [ code, --timeout=300 ] {
  mut t = $timeout
  while $t > 0 {
    $t = $t - 1
    let result = (do $code | complete)
    if ($result.exit_code == 0) {
      return
    }
    sleep 1sec
  }
}

def FzfHistory [ ] {
  let prefix = (commandline)
  let result = history | where {|it| ($it.exit_status == 0) and ($it.command starts-with $prefix)}
    | get command |each {|it| $it | str trim } |uniq
    | str replace --all (char newline) ' '
    | to text
    | fzf ;
  commandline edit --replace $result;
  commandline set-cursor --end
}

def FzfHistoryPwd [ ] {
  let prefix = (commandline)
    let p = (pwd)
    let result = history | where {|it| ($it.exit_status == 0) and ($it.command starts-with $prefix) and $it.cwd == $p}
      | get command |each {|it| $it | str trim } |uniq
      | str replace --all (char newline) ' '
      | to text
      | fzf ;
    commandline edit --replace $result;
    commandline set-cursor --end
}

const ctrl_r = {
  name: history_menu
  modifier: control
  keycode: char_r
  mode: [emacs, vi_insert, vi_normal]
  event: [
    {
      send: executehostcommand
      cmd: "FzfHistory"
    }
  ]
}

const alt_c = {
  name: history_pwd_menu
  modifier: alt
  keycode: char_c
  mode: [emacs, vi_insert, vi_normal]
  event: [
    {
      send: executehostcommand
      cmd: "FzfHistoryPwd"
    }
  ]
}

if (which fzf | is-not-empty) {
  $env.config.keybindings = $env.config.keybindings | append [$ctrl_r $alt_c]
}

def --env source-envrc [ path ] {
  open ($path | path expand)| lines | where {|it| $it starts-with "export" }|each {|it| $it |str replace 'export ' '' | split row "=" -n 2 }|reduce -f {} {|it, acc| $acc | upsert $it.0 $it.1 }| load-env
}


def "kube-node" [ ] {
  kubectl get node -o name | str replace -a "node/" ""|lines
}

def kube-node-usage [ node:string@"kube-node" ] {
  def cpu_to_int [ v ] {
    let v = ($v | into string)
    if "m" in $v {
      return ($v | str replace "m" "" -a|into int)
    }
    return (($v | into int) * 1000)

  }
  def memory_to_int [ v ] {
    let v = (echo $v | into filesize |into int)
    return $v
  }

  let pod_list = (kubectl get pods --all-namespaces --field-selector $"spec.nodeName=($node)" -o json|from yaml|get items)
  let resources = ($pod_list |each {|it|
    let cpu_limit = $it.spec.containers| each {|c| $c| get -i resources.limits.cpu |default 0} | reduce --fold 0 {|i, acc| $acc + (cpu_to_int $i)}
    let cpu_request = $it.spec.containers| each {|c| $c| get -i resources.requests.cpu |default 0} | reduce --fold 0 {|i, acc| $acc + (cpu_to_int  $i)}
    let memory_limit = $it.spec.containers| each {|c| $c| get -i resources.limits.memory |default 0} | reduce --fold 0 {|i, acc| $acc + (memory_to_int $i)}
    let memory_request = $it.spec.containers| each {|c| $c| get -i resources.requests.memory |default 0} | reduce --fold 0 {|i, acc| $acc + (memory_to_int  $i)}

    [$cpu_request, $cpu_limit, $memory_request, $memory_limit]
  }) | reduce --fold {node: $node,cpu_request: 0, cpu_limit: 0, memory_request: 0, memory_limit: 0} {|it, acc|
    $acc | upsert cpu_request ($acc.cpu_request + $it.0) | upsert cpu_limit ($acc.cpu_limit + $it.1) | upsert memory_request ($acc.memory_request + $it.2) | upsert memory_limit ($acc.memory_limit + $it.3)
  }
  let node_info = (kubectl get node $node -o json|from json)
  let top = (kubectl top node|from ssv|where NAME == $node|get -i 0|default {"CPU%": -1, "MEMORY%": -1})

  let resources = ($resources | upsert cpu_total (cpu_to_int $node_info.status.allocatable.cpu))
  let resources = ($resources | upsert memory_total (memory_to_int $node_info.status.allocatable.memory))
  let resources = ($resources | upsert cpu_usage ($resources.cpu_request * 100 / $resources.cpu_total))
  let resources = ($resources | upsert CPU% ($top|get "CPU%"))
  let resources = ($resources | upsert memory_usage ($resources.memory_request * 100 / $resources.memory_total))
  let resources = ($resources | upsert MEMORY% ($top|get "MEMORY%"))
  let resources = ($resources | reject cpu_limit memory_limit cpu_request )
  $resources
}

def --wrapped run-k8s-in-docker [ name:string=k0s, ...args ] {
  docker run -d --name $name --hostname $name --privileged --device /dev/kmsg --tmpfs /run -v /var/log/pods -v $"k0s-($name):/var/lib/k0s" ...$args -p 6443:6443 --cgroupns=host -v /sys/fs/cgroup:/sys/fs/cgroup:rw docker.io/k0sproject/k0s:latest k0s server --single
  docker exec -i $name k0s kubectl apply -f https://raw.githubusercontent.com/rancher/local-path-provisioner/v0.0.31/deploy/local-path-storage.yaml
}

def pod-last-reason [ pod ] {kubectl get pod $pod -o json |from json|get status.containerStatuses |each {|it| $it.lastState}}

def "scp-binary" [ --host:string@"ssh-host", ...args ] {
  $args | par-each -t 2 {|it| which $it | get 0.path | path expand } |each {|it|
    scp $it $"($host):~/"
  }
}

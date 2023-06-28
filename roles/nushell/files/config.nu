let-env config = ($env.config? | default {
  hooks: {
    pre_prompt: []
    pre_execution: []
  }
  keybindings: []
})
let-env config = ($env.config | upsert show_banner false)
let-env config = ($env.config | upsert edit_mode vi)
let-env EDITOR = nvim
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
let-env config.hooks.pre_prompt = ( $env.config.hooks.pre_prompt | append [{ ||
      let direnv = (direnv export json | from json)
      let direnv = if ($direnv | length) == 1 { $direnv } else { {} }
      $direnv | load-env
    }] )
let-env config = ($env.config | merge {
  history: {
    file_format: "sqlite"
    isolation: false
    sync_on_enter: false
  }
  hooks: {
    pre_prompt: $env.config.hooks.pre_prompt,
    pre_execution: $env.config.hooks.pre_execution,
    env_change: {cloud: [
      { |before, after|
        if ( $env.cloud == 1 ) {
            let-env PROMPT_COMMAND = { || create_left_prompt }
        }
      }
    ]}
}})

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
      nvim $af
    } else {
      let action = "edit"
      let cmd = $"<cmd>($action) ($af|str join ' ')<cr>"
      nvim --headless --noplugin --server $env.NVIM --remote-send $cmd
    }
  } else {
    /usr/bin/vim $af
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

def "zoxide-path" [cmd: string, offset: int] {
  let argv = ($cmd | str substring ..$offset | split row ' '| get 1)
  let r1 = (zoxide query -l $argv |lines)
  let r2 = (glob --no-file --depth 1 $argv)
  [$r1 $r2] | flatten
}

def-env z [...rest:string@zoxide-path] {
  let arg0 = ($rest | append '~').0
  let path = if (($rest | length) <= 1) and ($arg0 == '-' or ($arg0 | path expand | path type) == dir) {
    $arg0
  } else if ( $rest | last | path exists ) {
    $rest | last
  } else {
    (zoxide query --exclude $env.PWD -- $rest | str trim -r -c "\n")
  }
  cd $path
}

def-env zi  [...rest:string] {
  cd $'(zoxide query --interactive -- $rest | str trim -r -c "\n")'
}

def my-prompt [ ] {
  try {
    return (prompt)
  } catch {}
  try {
    return (starship prompt)
  } catch {}
  try {
    return ([$"(hostname) (pwd)"] | str join)
  } catch {}
}

let-env PROMPT_COMMAND = {|| ([(my-prompt) "\n" ->] | str join) }
let-env PROMPT_COMMAND_RIGHT = ""

use ~/nu_scripts/modules/kubernetes/kubernetes.nu *
use ~/nu_scripts/modules/git/git-v2.nu *
use ~/nu_scripts/modules/network/ssh.nu *
use ~/nu_scripts/modules/docker/docker.nu *
use ~/nu_scripts/modules/nvim/nvim.nu *

let-env config = ($env.config | upsert keybindings ( $env.config.keybindings | append [{ name: custom modifier: alt keycode: char_l mode: [emacs vi_normal vi_insert]  event: { until: [{ send: menu name: completion_menu } { send: menunext } ]} }] ))
let-env config = ($env.config | upsert keybindings ( $env.config.keybindings | append [{ name: custom modifier: alt keycode: char_h mode: [emacs vi_normal vi_insert]  event: { send: menuprevious } }] ))
let-env config = ($env.config | upsert keybindings ( $env.config.keybindings | append [{ name: custom modifier:alt keycode: char_j mode: [emacs vi_normal vi_insert]  event: { send: down } }] ))
let-env config = ($env.config | upsert keybindings ( $env.config.keybindings | append [{ name: custom modifier:alt keycode: char_k mode: [emacs vi_normal vi_insert]  event: { send: up } }] ))
let-env config = ($env.config | upsert keybindings ( $env.config.keybindings | append [{ name: custom modifier:control keycode: char_f mode: [emacs vi_normal vi_insert]  event: { send: HistoryHintComplete } }] ))
let-env config = ($env.config | upsert keybindings ( $env.config.keybindings | append [{ name: custom modifier:alt keycode: char_f mode: [emacs vi_normal vi_insert]  event: { send: HistoryHintWordComplete } }] ))
let-env config = ($env.config | upsert keybindings ( $env.config.keybindings | append [{ name: custom modifier:alt keycode: char_q mode: [emacs vi_normal vi_insert]  event: [{edit: Clear}, {edit: InsertString, value: "workspace"}, {send: Enter}] }] ))
def-env s [ ] {
  let path = (zoxide query -i)
  let id = (shells|enumerate | par-each -t 2 {|it| if ($it.item.path == $path) {$it.index} else {-1}} | reduce {|a, b| if ( $a > $b) {$a} else {$b}})
  if ( ($id |into int) >= 0) {
    g ($id |into int)
  } else {
    enter $path
  }
}

def h [ pattern ] {
  help commands | where name =~ $pattern or category =~ $pattern
}

source ~/.config/custom.nu

let-env config = ($env.config | upsert hooks.env_change.PWD {
    [
        {
            condition: {|before, after|
                ($after | path join local.nu | path exists)
            }
            code: "overlay use local.nu"
        }
    ]
})

let-env NU_LIB_DIRS = [~/nu_scripts/]
let-env config = ($env.config | upsert keybindings ( $env.config.keybindings | append [{
    name: fuzzy_module
    modifier: control
    keycode: char_g
    mode: [emacs, vi_normal, vi_insert]
    event: {
        send: executehostcommand
        cmd: '
            let cmd = (commandline)
            let t = (pueue add -p -- $cmd)
            sleep 1sec
            pueue follow $t
            commandline -r ''
        '
    }
}] ))

let-env config = ($env.config | upsert keybindings ( $env.config.keybindings | append [{
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

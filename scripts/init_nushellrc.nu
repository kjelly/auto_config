#!/usr/bin/env nu

def main [ ] {
  mkdir ~/.config/nushell
  config nu --default | save -f $nu.config-path
  config env --default|save -f $nu.env-path

  [
    "https://raw.githubusercontent.com/kjelly/auto_config/master/roles/nushell/files/config.nu",
    "https://raw.githubusercontent.com/kjelly/auto_config/master/roles/nushell/files/clipboard.nu",
    "https://raw.githubusercontent.com/kjelly/auto_config/master/roles/nushell/files/pueue.nu",
    "https://raw.githubusercontent.com/ddanier/nur/main/scripts/nur-completions.nu",
  ] | par-each -t 1 {|it|
    "\n" + (http get $it)
  } | str join "\n" | save -a $nu.config-path

  [
    "https://raw.githubusercontent.com/kjelly/auto_config/master/roles/nushell/files/env.nu",
  ] | par-each -t 1 {|it|
    "\n" + (http get $it)
  } | str join "\n" | save -a $nu.env-path

  touch ~/.config/custom.nu

  mkdir ~/.config/nushell/scripts
  if (which pueue | is-not-empty ) {
    let path = ($nu.default-config-dir | path join 'scripts' pueue.nu)
    pueue completions nushell| save -f $path
    "\nuse ($nu.default-config-dir | path join 'scripts' 'pueue.nu') *\n" | save -f -a $nu.config-path
  }

  if ("~/.asdf/asdf.nu" | path exists) {
    "\n$env.ASDF_DIR = ($env.HOME | path join '.asdf')\nsource " + ($env.HOME | path join '.asdf/asdf.nu') | save --append $nu.config-path
  }

  mkdir ~/.config/nushell/autoload
  if (which mise | is-not-empty) {
    ^mise activate nu | save -f ~/.config/nushell/autoload/mise.nu

  }

  def download-github-module [ name_list: list, repo: string, --prefix:string=""] {
    let url = $"https://github.com/($repo)/archive/refs/heads/main.zip"
    let path = ($nu.default-config-dir | path join 'scripts')
    mkdir $path
    let project = ($repo|split row '/'|last)
    wget $url -O /tmp/a.zip
    cd /tmp/
    unzip -o /tmp/a.zip
    $name_list | each {|name|
      let p = ( [$prefix, $name] | path join)
      print $p
      cp -r $"/tmp/($project)-main/($p)" $path
    }
  }

  download-github-module [git docker nvim argx lg] "nushell/nu_scripts" --prefix "modules"
  download-github-module ["kubernetes"] "fj0r/kubernetes.nu"
  download-github-module ["argx"] "fj0r/argx.nu"


  "
  use std-rfc clip;
  use ($nu.default-config-dir | path join 'scripts' 'kubernetes') *
  use ($nu.default-config-dir | path join 'scripts' 'kubernetes' 'shortcut.nu') *
  use ($nu.default-config-dir | path join 'scripts' 'docker') *
  " | save -f $"($nu.default-config-dir)/autoload/my-modules.nu"

}

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

  def download-module [ name: string ] {
    let path = ($nu.default-config-dir | path join 'scripts' $name)
    print $path
    mkdir $path
    cd $path
    let files = (http get $"https://api.github.com/repos/nushell/nu_scripts/contents/modules/($name)/")
    $files | par-each -t 1 {|it|
      http get $it.download_url | save -f $it.name
    }
  }

  mkdir ~/.config/nushell/scripts
  if (which pueue | is-not-empty ) {
    let path = ($nu.default-config-dir | path join 'scripts' pueue.nu)
    pueue completions nushell| save -f $path
    "\nuse ($nu.default-config-dir | path join 'scripts' 'pueue.nu') *\n" | save -f -a $nu.config-path
  }

  [kubernetes git docker nvim argx lg] | par-each -t 1 {|it|
    download-module $it
    null
  }

  if ("~/.asdf/asdf.nu" | path exists) {
    "\n$env.ASDF_DIR = ($env.HOME | path join '.asdf')\nsource " + ($env.HOME | path join '.asdf/asdf.nu') | save --append $nu.config-path
  }

  mkdir ~/.config/nushell/autoload
  if (which mise | is-not-empty) {
    ^mise activate nu | save -f ~/.config/nushell/autoload/mise.nu

  }

  def download-github-module [ name: string, repo: string, repo_path: string ] {
    let path = ($nu.default-config-dir | path join 'scripts' $name)
    print $path
    mkdir $path
    cd $path
    let files = (http get $"https://api.github.com/repos/($repo)/contents/($repo_path)/"|filter {|it| $it.type == "file"})
    $files | par-each -t 1 {|it|
      http get $it.download_url | save -f $it.name
    }
  }

  download-github-module "kubernetes" "fj0r/kubernetes.nu" "kubernetes"
  download-github-module "argx" "fj0r/argx.nu" "argx"


  "
  use std-rfc clip;
  use ($nu.default-config-dir | path join 'scripts' 'kubernetes') *
  use ($nu.default-config-dir | path join 'scripts' 'kubernetes' 'shortcut.nu') *
  use ($nu.default-config-dir | path join 'scripts' 'docker') *
  " | save -f $"($nu.default-config-dir)/autoload/my-modules.nu"

}

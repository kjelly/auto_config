#!/usr/bin/env nu

# if (echo ~/nu_scripts/ | path exists) {
#   cd ~/nu_scripts/
#   git pull
# } else {
#   git clone https://github.com/nushell/nu_scripts ~/nu_scripts/
# }

mkdir ~/.config/nushell
let commit = (http get https://api.github.com/repos/nushell/nushell/tags|get 0.commit.sha )

http get $"https://raw.githubusercontent.com/nushell/nushell/($commit)/crates/nu-utils/src/sample_config/default_config.nu" | save -f $nu.config-path
http get $"https://raw.githubusercontent.com/nushell/nushell/($commit)/crates/nu-utils/src/sample_config/default_env.nu" | save -f $nu.env-path

http get https://raw.githubusercontent.com/kjelly/auto_config/master/roles/nushell/files/config.nu | save -a $nu.config-path
http get https://raw.githubusercontent.com/kjelly/auto_config/master/roles/nushell/files/clipboard.nu | save -a $nu.config-path
http get https://raw.githubusercontent.com/kjelly/auto_config/master/roles/nushell/files/pueue.nu | save -a $nu.config-path
http get https://raw.githubusercontent.com/kjelly/auto_config/master/roles/nushell/files/env.nu | save -a $nu.env-path

touch ~/.config/custom.nu

def download-module [ name: string ] {
  let path = ($nu.default-config-dir | path join 'scripts' $name)
  print $path
  mkdir $path
  cd $path
  let files = (http get $"https://api.github.com/repos/nushell/nu_scripts/contents/modules/($name)/")
  $files | par-each -t 2 {|it|
    http get $it.download_url | save -f $it.name
  }
}

[kubernetes git docker nvim argx] | par-each -t 2 {|it|
  download-module $it
}

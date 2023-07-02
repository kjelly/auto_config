#!/usr/bin/env nu

if (echo ~/nu_scripts/ | path exists) {
  cd ~/nu_scripts/
  git pull
} else {
  git clone https://github.com/nushell/nu_scripts ~/nu_scripts/
}

mkdir ~/.config/nushell
let commit = (http get https://api.github.com/repos/nushell/nushell/tags|get 0.commit.sha )

http get $"https://raw.githubusercontent.com/nushell/nushell/($commit)/crates/nu-utils/src/sample_config/default_config.nu" | save -f ~/.config/nushell/config.nu
http get $"https://raw.githubusercontent.com/nushell/nushell/($commit)/crates/nu-utils/src/sample_config/default_env.nu" | save -f ~/.config/nushell/env.nu

touch ~/.config/custom.nu

http get https://raw.githubusercontent.com/kjelly/auto_config/master/roles/nushell/files/config.nu | tee -a ~/.config/nushell/config.nu

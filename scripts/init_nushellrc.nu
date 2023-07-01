#!/usr/bin/env nu

if (echo ~/nu_scripts/ | path exists) {
  cd ~/nu_scripts/
  git pull
} else {
  git clone https://github.com/nushell/nu_scripts ~/nu_scripts/
}

mkdir ~/.config/nushell
let commit = (http get https://api.github.com/repos/nushell/nushell/releases/latest|get target_commitish)

http get $"https://raw.githubusercontent.com/nushell/nushell/($commit)/crates/nu-utils/src/sample_config/default_config.nu" | save -f ~/.config/nushell/config.nu
http get $"https://raw.githubusercontent.com/nushell/nushell/($commit)/crates/nu-utils/src/sample_config/default_env.nu" | save -f ~/.config/nushell/env.nu


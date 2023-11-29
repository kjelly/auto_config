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

cd /tmp
wget https://github.com/nushell/nu_scripts/archive/refs/heads/main.zip -O main.zip
unzip main.zip
rm -rf ~/nu_scripts
mv nu_scripts-main ~/nu_scripts

#!/usr/bin/env nu


def get-arch [ ] {
  lscpu | lines | get 0 | split row : | get 1 | str trim | split row _ | first
}


def download-only [ repo ] {
  let info = (http get $"https://api.github.com/repos/($repo)/releases/latest"|get assets|where name =~ "linux" and name =~ (get-arch) | { url: $in.0.browser_download_url name: $in.0.name})
  wget $info.url -O $info.name
}

def download-binary-url [ url ] {
  rm -rf /tmp/aa/
  mkdir /tmp/aa/
  let name = ( $url | split row '?' | get 0 | split row '/'|last)
  wget $url -O $name
  if ( $name | str ends-with '.gz' ) {
    tar zxvf $name -C /tmp/aa
  } else if ( $name | str ends-with '.zip' ) {
    unzip $name -d /tmp/aa
  } else {
    tar xvf $name -C /tmp/aa
  }
  ^find /tmp/aa/ -type f -executable|lines|each {|it| cp $it ~/bin/ }
}



def download-binary [ repo ] {
  rm -rf /tmp/aa/
  mkdir /tmp/aa/
  let info = (http get $"https://api.github.com/repos/($repo)/releases/latest"|get assets|where name =~ "linux" and name =~ (get-arch) | { url: $in.0.browser_download_url name: $in.0.name})
  wget $info.url -O $info.name
  if ( $info.name | str ends-with '.gz' ) {
    tar zxvf $info.name -C /tmp/aa
  } else if ( $info.name | str ends-with '.zip' ) {
    unzip $info.name -d /tmp/aa
  } else {
    tar xvf $info.name -C /tmp/aa
  }
  ^find /tmp/aa/ -type f -executable|lines|each {|it| cp $it ~/bin/ }
}

def download-all [ repo ] {
  rm -rf /tmp/aa/
  mkdir /tmp/aa/
  let info = (http get $"https://api.github.com/repos/($repo)/releases/latest"|get assets|where name =~ "linux" and name =~ (get-arch) |each {|it| {name: $it.name url: $it.browser_download_url} } )
  $info | par-each {|it|
    wget $it.url -O $it.name
    if ( $it.name | str ends-with '.gz' ) {
      tar zxvf $it.name -C /tmp/aa
    } else if ( $it.name | str ends-with '.zip' ) {
      unzip $it.name -d /tmp/aa
    } else if ( $it.name | str ends-with '.xz' ) {
      tar xvf $it.name -C /tmp/aa
    } else {
      if ( file $it.name| str contains "ELF"  ) {
        chmod +x $it.name
        let new = ($it.name|str replace -a - _|split column -c _ name|get 0.name)
        mv -f $it.name $new
        mv -f $new ~/bin/
      }

    }
  }
   ^find /tmp/aa/ -type f -executable|lines|each {|it| cp $it ~/bin/ }
}

def download-deb [ repo ] {
  let info = (http get $"https://api.github.com/repos/($repo)/releases/latest"|get assets|where name =~ "deb" |{name: $in.0.name url: $in.0.browser_download_url})
  wget $info.url -O $info.name
  sudo dpkg -i $info.name
}

def download-appimage [ repo ] {

}


def main [ ] {
  # download nushell/nushell
  # download-binary casey/just
  # download-binary ajeetdsouza/zoxide
  # download-binary Ryooooooga/croque
  # download-binary denoland/deno
  download-all Nukesor/pueue
  # download-binary ellie/atuin
  # download-binary ducaale/xh
  # download-binary-url https://github.com/orhun/halp/releases/download/v0.1.6/halp-0.1.6-x86_64-unknown-linux-gnu.tar.gz
  # download-binary denisidoro/navi

  # download-binary YesSeri/xny-cli
  # download-binary-url https://github.com/hush-shell/hush/releases/download/v0.1.4-alpha/hush-0.1.4-static-x86_64.tar.gz
}


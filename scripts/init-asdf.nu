def asdf-install [  package, version? ] {
  let version = (if $version == null {asdf list all $package|last} else {$version})
  asdf install $package $version
  asdf global $package $version
}

def main [ ] {
  asdf plugin add nodejs https://github.com/asdf-vm/asdf-nodejs.git
  asdf plugin-add poetry https://github.com/asdf-community/asdf-poetry.git
  asdf plugin-add python

  asdf-install python
  asdf-install nodejs
  asdf-install poetry

}

#!/bin/bash

get_latest_release() {
  curl --silent "https://api.github.com/repos/$1/releases/latest" | # Get latest release from GitHub api
    grep '"tag_name":' |                                            # Get tag line
    sed -E 's/.*"([^"]+)".*/\1/'                                    # Pluck JSON value
}

version=`get_latest_release 'cdr/code-server'`
echo $version
export versionNumber=${version/v/}

URL="https://github.com/cdr/code-server/releases/download/$version/code-server-$versionNumber-linux-amd64.tar.gz"

mkdir ~/coder
cd ~/coder

rm -rf ~/coder/code-server*

wget $URL -O code-server.tar.gz

tar zxvf code-server.tar.gz

ln -s code-server*/code-server .



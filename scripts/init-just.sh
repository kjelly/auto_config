#!/bin/bash

version=$(git -c 'versionsort.suffix=-' \
    ls-remote --exit-code --refs --sort='version:refname' --tags https://github.com/casey/just '*.*.*' \
    | tail --lines=1 \
    | cut --delimiter='/' --fields=3)



echo $version

wget -O /tmp/just.tar.gz https://github.com/casey/just/releases/download/$version/just-${version}-x86_64-unknown-linux-musl.tar.gz
tar zxvf /tmp/just.tar.gz -C /tmp/
sudo mv /tmp/just /bin/

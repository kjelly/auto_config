#!/bin/bash

ls $HOME/.config/coc/extensions/node_modules|grep coc|sort |tee ~/auto_config/roles/vim/files/coc-extensions.txt


#!/bin/bash

cat ~/auto_config/roles/vim/files/coc-extensions.txt |xargs -L1 -I {} nvim "+CocInstall {}" "+qa!"

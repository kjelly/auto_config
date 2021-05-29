#!/usr/bin/env python3
import random
import os


colors = [
    "gruvbox-material",
    "space-vim-dark",
    "material",
    "gruvbox-flat",
    "tokyonight",
]

bad_in_dark_mode = [
    "onedark",
    "space-vim-dark",
    "dracula",
    "deep-space",
    "moonfly",
    "ayu",
    "iceberg",
    "PaperColor",
    "doom-one",
    "material",
    "darcula-solid",
]

color = random.choice(colors + bad_in_dark_mode)
with open(os.path.expanduser('~/.vim_custom.vim'), 'r') as ftr:
    data = ftr.read().strip().split('\n')

data = [i for i in data if 'colorscheme' not in i]
data.append(f'colorscheme {color}')

with open(os.path.expanduser('~/.vim_custom.vim'), 'w') as ftr:
    ftr.write('\n'.join(data))

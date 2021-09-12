#!/usr/bin/env python3
import os
import random

colors = [
    "gruvbox-material",
    "space-vim-dark",
    "material",
    "gruvbox-flat",
    "tokyonight",
]

bad_in_dark_mode = [
    "onedark",
    "dracula",
    "deep-space",
    "moonfly",
    "ayu",
    "iceberg",
    "PaperColor",
    "doom-one",
    "darcula-solid",
]

treesitter = [
    "darcula-solid",  # treesitter
    "dracula",  # treesitter
    "material",  # treesitter
    "gruvbox-flat",  # treesitter
    "tokyonight",  # treesitter
    "calvera",  # treesitter
    "darkplus",  # treesitter
    "aurora",
    "nightfox",
    "aurora",
    'vn-night',
    'aquarium',
    'catppuccino',
    'edge',
    'everforest',
    'calvera',
    'omni',
    'zenbones',
]

color = random.choice(list(dict.fromkeys(treesitter)))
with open(os.path.expanduser('~/.vim_custom.vim'), 'r') as ftr:
    data = ftr.read().strip().split('\n')

data = [i for i in data if 'colorscheme' not in i]
data.append(f'colorscheme {color}')

with open(os.path.expanduser('~/.vim_custom.vim'), 'w') as ftr:
    ftr.write('\n'.join(data))

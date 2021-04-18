#!/usr/bin/env python3
import random
import os


colors = [
    "deep-space",
    "gruvbox-material",
    "iceberg",
    "onedark",
    "space-vim-dark",
]
color = random.choice(colors)
with open(os.path.expanduser('~/.vim_custom.vim'), 'r') as ftr:
    data = ftr.read().strip().split('\n')

data = [i for i in data if 'colorscheme' not in i]
data.append(f'colorscheme {color}')

with open(os.path.expanduser('~/.vim_custom.vim'), 'w') as ftr:
    ftr.write('\n'.join(data))

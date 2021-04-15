#!/usr/bin/env python3
import random
import os

t = '''
let g:leetcode_browser='firefox'
let g:leetcode_hide_paid_only='1'
colorscheme {color}
'''

colors = [
    "moonfly",
    "deep-space",
    "gruvbox-material",
    "iceberg",
    "onedark",
    "space-vim-dark",
]

with open(os.path.expanduser('~/.vim_custom.vim'), 'w') as ftr:
    ftr.write(t.format(color=random.choice(colors)))

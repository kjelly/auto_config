#!/usr/bin/env python3
import glob
import json
import os
import random
import sys


def find_all_color_schemes():
    nvim_path = os.path.expanduser('~/.config/nvim/plugged/')
    color_scheme_dir = []
    for i in os.listdir(nvim_path):
        p = os.path.abspath(os.path.join(nvim_path, i, 'colors'))
        if os.path.exists(p):
            color_scheme_dir.append(p)

    ret = []
    for i in color_scheme_dir:
        ret.extend(glob.glob(f'{i}/*.vim'))
    ret = [os.path.basename(i)[:-4] for i in ret]
    return ret


def main():
    colors = []
    color_json_path = os.path.expanduser('~/.colors.json')
    if len(sys.argv) > 1 or not os.path.isfile(color_json_path):
        colors = find_all_color_schemes()
        with open(color_json_path, 'w') as f:
            json.dump(colors, f)
    else:
        with open(color_json_path, 'r') as f:
            colors = json.load(f)

    color = random.choice(colors)
    with open(os.path.expanduser('~/.vim_custom.vim'), 'r') as ftr:
        data = ftr.read().strip().split('\n')
    data = [i for i in data if 'colorscheme' not in i]
    data.append(f'colorscheme {color}')

    with open(os.path.expanduser('~/.vim_custom.vim'), 'w') as ftr:
        ftr.write('\n'.join(data))


if __name__ == "__main__":
    main()

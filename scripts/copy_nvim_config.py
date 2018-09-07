#!/usr/bin/env python

import os

def main():
    os.system('mkdir -p ~/.config')
    lst = os.listdir('/home')
    for i in lst:
        p = '/home/%s' % i
        home = os.path.expanduser('~')
        if p == home:
            continue
        if os.path.exists('/home/%s/.config/nvim/bin' % i):
            os.system('cp -r /home/%s/.config/nvim ~/.config/' % i)
            os.system('cp -r /home/%s/.fzf ~/' % i)


if __name__ == "__main__":
    main()

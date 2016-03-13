#!/usr/bin/env python
import sys
import os

def main():
    path = sys.argv[1]
    part = path.split('/')
    if len(part) < 4:
        print('/'.join(part))
        return
    part[-4] = ' [ %s ] ' % part[-4] if part[-4] != '' else ''
    if len(part) < 6:
        print('/'.join(part))
        return
    part[-6] = ' [ %s ] ' % part[-6] if part[-6] != '' else ''
    print('/'.join(part))


if __name__ == '__main__':
    main()

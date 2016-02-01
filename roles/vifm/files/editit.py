#!/usr/bin/python

import sys
import os
import mimetypes
import magic


def open_file(path):
    if 'text' in magic.from_file(path):
        os.system("vim %s" % path)
    else:
        os.system("xxd %s |less" % path)


def main():
    MB = 1024 * 1024
    file_name = sys.argv[1]
    file_size = os.path.getsize(file_name)
    if file_size > 512 * MB:
        print('file size: %d MB' % (file_size / (1024 * 1024)))
        ans = raw_input('Do you want to open it? (y/n) ')
        if ans.strip() == 'y':
            open_file(file_name)
    else:
        open_file(file_name)


if __name__ == '__main__':
    main()

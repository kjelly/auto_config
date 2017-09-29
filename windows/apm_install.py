#!/usr/bin/env python
import os
import shutil

HOME = os.path.expanduser('~')
EXECUTE_PATH = os.path.abspath(os.path.dirname(__file__))


def get_package_list():
    file_path = os.path.join(EXECUTE_PATH,
                             '../roles/atom/files/base_package_list')
    with open(file_path, 'r') as ftr:
        return ftr.read().split()


def copy_config():
    base = os.path.join(EXECUTE_PATH, '../roles/atom/files')
    for name in ['config.cson', 'keymap.cson', 'styles.less']:
        shutil.copyfile(os.path.join(base, name),
                        os.path.join(HOME, '.atom', name))


def main():
    for i in get_package_list():
        os.system("apm install %s" % i)
    copy_config()


if __name__ == '__main__':
    main()

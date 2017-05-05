#!/usr/bin/env python
import os
import shutil

HOME = os.path.expanduser('~')
VS_CODE = os.path.join(HOME,"AppData", "Roaming", "Code", "User")
EXECUTE_PATH = os.path.abspath(os.path.dirname(__file__))

def get_package_list():
    file_path = os.path.join(EXECUTE_PATH, '../roles/vscode/files/ext_list')
    with open(file_path, 'r') as ftr:
        return ftr.read().split()


def copy_config():
    base = os.path.join(EXECUTE_PATH, '../roles/vscode/files')
    for name in ["keybindings.json", "settings.json"]:
        shutil.copyfile(os.path.join(base, name),
                        os.path.join(VS_CODE, name))


def main():
    for i in get_package_list():
        os.system("code --install-extension %s" % i)
    copy_config()

if __name__ == '__main__':
    main()

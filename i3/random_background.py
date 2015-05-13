#! /usr/bin/env python
import sys
import os
import os.path
import random


def get_all_background_path():
    folder_path = sys.argv[1]
    ret = []
    for base_path, dir_name, file_name_list in os.walk(folder_path):
        for file_name in file_name_list:
            ret.append(os.path.join(base_path, file_name))
    return [os.path.abspath(i) for i in ret]


def set_background(path):
    os.system("feh --bg-scale %s" % path)



if __name__ == '__main__':
    set_background(random.choice(get_all_background_path()))


#! /usr/bin/env python
from subprocess import check_output
import re
from collections import defaultdict
import os


mode_pattern = re.compile('(?P<mode>\d+x\d+)\s+\d+\.\d+')


def get_device(line):
    if ' connected' in line:
        return line.split(' ')[0]
    return None

def get_mode(line):
    result = mode_pattern.search(line)
    # pdb.set_trace()
    if result:
        return result.groupdict()['mode']
    return None


def find_disconnected(line):
    return line.find(' disconnected') >= 0

def get_xrandr_result():
    output = check_output('xrandr')
    output = output.split('\n')

    result = defaultdict(lambda: [])
    device = None

    for i in output:
        if find_disconnected(i):
            device = None
        elif get_device(i):
            device = get_device(i)

        if device is None:
            continue

        mode = get_mode(i)
        if mode is None:
            continue
        result[device].append(mode)
    return result


def auto_config_mode():
    device_list = get_xrandr_result()
    for i in device_list:
        mode = device_list[i][0]
        os.system("xrandr --output %s --mode %s" % (i, mode))
    device_keys = device_list.keys()
    for index, device in enumerate(device_keys[1:]):
        left_device = device_keys[index - 1]
        right_device = device_keys[index]
        os.system("xrandr --output %s --left-of %s" % (left_device, right_device))


if __name__ == '__main__':
    auto_config_mode()

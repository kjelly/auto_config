#! /usr/bin/env python3
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
    output = output.decode('utf-8').split('\n')

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


def get_left_or_right():
    home_dir = os.path.expanduser('~')
    config_path = os.path.join(home_dir, '.xrandr_config')
    try:
        with open(config_path, 'r') as ftr:
            return ftr.readline().strip()
    except FileNotFoundError:
        return 'right'


def auto_config_mode():
    device_list = get_xrandr_result()
    for i in device_list:
        mode = device_list[i][0]
        os.system("xrandr --output %s --mode %s" % (i, mode))
    device_keys = list(device_list.keys())
    for index, _ in enumerate(device_keys[1:]):
        left_device = device_keys[index - 1]
        right_device = device_keys[index]
        direction = get_left_or_right()
        os.system("xrandr --output %s --%s-of %s" % (left_device,
                                                     direction, right_device))


if __name__ == '__main__':
    auto_config_mode()

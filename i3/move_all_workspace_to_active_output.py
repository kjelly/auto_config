#!/usr/bin/env python
import i3
from subprocess import check_output
import re
from collections import defaultdict
import os
from lib import get_active_workspace


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
    device_name_list = device_list.keys()
    original_workspace = get_active_workspace()
    for i in xrange(1, 10):
        i3.workspace(str(i))
        getattr(i3, 'move_workspace_to_output_' + device_name_list[0])()
    i3.workspace(original_workspace['name'])


if __name__ == '__main__':
    auto_config_mode()

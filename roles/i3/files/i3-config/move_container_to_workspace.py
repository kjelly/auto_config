#!/usr/bin/env python3
import i3
import json
from collections import defaultdict
import subprocess
from lib import dmenu, dmenu_cmd


def handle_workspace(workspace):
    ret = {}
    ret['name'] = workspace['name']
    ret['num'] = workspace['num']
    return ret


def handle_output(output):
    '''
    output[1] for content
    '''
    ret = []
    workspaces = output[1]['nodes']
    for i in workspaces:
        ret.append(handle_workspace(i))
    return ret


def main():
    tree = i3.get_tree()
    result = []
    for output in tree['nodes']:
        if output['name'].startswith('__'):
            continue
        result.extend(handle_output(output['nodes']))
    print(result)
    text_list = []
    for workspace in result:
        text_list.append('%s -> #%s' % (workspace['name'], workspace['num']))

    answer = dmenu(sorted(text_list), dmenu_cmd('select window: ', ))
    if answer:
        num = answer.split('#')[-1]
        i3.workspace(num)


if __name__ == '__main__':
    main()

#!/usr/bin/env python3
import i3
import json
from collections import defaultdict
import subprocess
from lib import dmenu, dmenu_cmd


def handle_window(window):
    ret = []
    if window['name'] is None:
        for i in window['nodes']:
            ret.extend(handle_window(i))
    else:
        ret.append({
            'name': window['name'],
            'id': window['window']
         })
    return ret


def handle_workspace(workspace):
    ret = defaultdict(lambda: [])
    windows = workspace['nodes']
    name = workspace['name']
    for i in windows:
        ret[name].extend(handle_window(i))
    return ret


def handle_output(output):
    '''
    output[1] for content
    '''
    ret = {}
    workspaces = output[1]['nodes']
    for i in workspaces:
        ret.update(handle_workspace(i))
    return ret


def main():
    tree = i3.get_tree()
    result = {}
    for output in tree['nodes']:
        if output['name'].startswith('__'):
            continue
        result.update(handle_output(output['nodes']))
    text_list = []
    for workspace in result:
        for win in result[workspace]:
            text_list.append("[{workspace}] -> {name} #{wid}".format(wid=win['id'],
                                                                workspace=workspace,
                                                                name=win['name']))
    answer = dmenu(sorted(text_list), dmenu_cmd('select window: ', ))
    if answer:
        wid = answer.split('#')[-1]
        i3.focus(id=wid)
        pass


if __name__ == '__main__':
    main()

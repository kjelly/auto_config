#!/usr/bin/env python3
import i3
import os
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
            'id': window['window'],
            'focused': window['focused']
         })
    return ret



def handle_workspace(workspace):
    ret = defaultdict(lambda: [])
    name = workspace['name']
    windows = []
    for i in workspace['nodes']:
        windows.extend(handle_window(i))
    focused = any([i['focused'] for i in windows])
    return {
        'name': workspace['name'],
        'focused': workspace['focused'] or focused
    }


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
    result = {}
    for output in tree['nodes']:
        if output['name'].startswith('__'):
            continue
        result[output['name']] = handle_output(output['nodes'])
    text_list = []
    for key in result:
        tmp_text = '%s: ' % key
        tmp_text += ','.join([i['name'] for i in result[key]])
        for i in result[key]:
            if i['focused']:
                focused = i['name']
        text_list.append(tmp_text)
    text = '%s\n\nfocused: %s ' % ('\n\n'.join(text_list), focused)
    os.system('notify-send "workspace info" "%s"' % text)


if __name__ == '__main__':
    main()

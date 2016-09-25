#!/usr/bin/env python3
import i3
import json
from collections import defaultdict
import subprocess
import os
from lib import dmenu, dmenu_cmd




def get_active_output_name(win):
    if win is None:
        return None
    outputs = i3.get_outputs()
    for i in outputs:
        if i['active'] and i['current_workspace'] == win['workspace']:
            return i['name']
    return None



def handle_window(window, workspace_name):
    ret = []
    if window['name'] is None:
        for i in window['nodes']:
            ret.extend(handle_window(i, workspace_name))
    else:
        obj = {
            'name': window['name'],
            'id': window['window'],
            'class': window['window_properties']['class'] if 'window_properties' in window else None,
            'focused': window['focused'],
            'workspace': workspace_name,

        }
        ret.append(obj)
    return ret


def handle_workspace(workspace):
    ret = defaultdict(lambda: [])
    windows = workspace['nodes']
    name = workspace['name']
    print(workspace)
    for i in windows:
        ret[name].extend(handle_window(i, name))
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
    win_map = {}
    focused_window = None
    for output in tree['nodes']:
        if output['name'].startswith('__'):
            continue
        result.update(handle_output(output['nodes']))
    text_list = []
    for workspace in result:
        for win in result[workspace]:
            text_list.append(u"{kind} [{workspace}] -> {name} #{wid}".format(wid=win['id'],
                                                                workspace=workspace,
                                                                kind=win['class'],
                                                                name=win['name']))
            win_map[win['id']] = win
            if win['focused']:
                focused_window = win
    old_output = get_active_output_name(focused_window)
    answer = dmenu(sorted(text_list), dmenu_cmd('select window: ', ))
    if answer:
        wid = answer.split('#')[-1]
        i3.focus(id=wid)
        if old_output != get_active_output_name(win_map[int(wid)]):
            os.system("i3-msg 'move workspace to output left'")


if __name__ == '__main__':
    main()

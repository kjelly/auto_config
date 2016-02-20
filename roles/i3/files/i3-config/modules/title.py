#/usr/bin/env python3
# coding=utf-8
import i3
import json
from collections import defaultdict
from time import time
from subprocess import check_output


focused = False
focused_workspace = None
focus_on_workspace = False


def handle_window(window):
    global focused
    ret = []
    if window['name'] is None:
        for i in window['nodes']:
            ret.extend(handle_window(i))
    else:
        ret.append({
            'name': window['name'],
            'id': window['window'],
            'focused': window['focused'],
         })
        if window['focused']:
            focused = True
    return ret


def handle_workspace(workspace):
    global focused
    global focused_workspace
    global focus_on_workspace
    ret = defaultdict(lambda: [])
    windows = workspace['nodes']
    num = workspace['num']
    for i in windows:
        ret[num].extend(handle_window(i))
        if focused == True:
            focused_workspace = num
            focused = False
    if workspace['focused']:
        focused_workspace = num
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


class Py3status:
    """
    Simply output the currently logged in user in i3bar.

    Inspired by i3 FAQ:
        https://faq.i3wm.org/question/1618/add-user-name-to-status-bar/
    """
    def title(self, i3status_output_json, i3status_config):
        """
        We use the getpass module to get the current user.
        """
        # the current user doesnt change so much, cache it good
        CACHE_TIMEOUT = 1

        try:

            tree = json.loads(check_output('i3-msg -t get_tree', shell=True).decode('utf-8'))
            result = {}
            for output in tree['nodes']:
                if output['name'].startswith('__'):
                    continue
                result.update(handle_output(output['nodes']))
            title_list = []
            index = 0
            pos_info = None
            if focused_workspace in result:
                for i in result[focused_workspace]:
                    index += 1
                    name = i['name'].strip()[:30]
                    title = name
                    if i['focused']:
                        pos_info = '%d@%d' % (index, len(result[focused_workspace]))
                        title_list.append('  >' + title + '<  ')
                    else:
                        title_list.append(title)
                text = pos_info + '|' +  '|'.join(title_list)
            else:
                text = 'workspace: %s' % focused_workspace

        except Exception as e:
            text = str(e)

        response = {'full_text': text, 'name': 'title'}
        response['cached_until'] = time() + CACHE_TIMEOUT
        return (0, response)


def main():
    o = Py3status()
    print(o.title(1,1))


if __name__ == '__main__':
    main()

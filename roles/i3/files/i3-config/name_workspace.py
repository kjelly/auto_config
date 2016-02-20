#!/usr/bin/env python3
import i3
import subprocess


def dmenu(options, dmenu):
    '''Call dmenu with a list of options.'''

    cmd = subprocess.Popen(dmenu,
                           shell=True,
                           stdin=subprocess.PIPE,
                           stdout=subprocess.PIPE,
                           stderr=subprocess.PIPE)
    stdout, _ = cmd.communicate('\n'.join(options).encode('utf-8'))
    return stdout.decode('utf-8').strip('\n')


def main():
    workspaces = i3.get_workspaces()
    for i in workspaces:
        if i['focused']:
            focused_workspace_num = i['num']
    answer = dmenu([], 'dmenu')
    if answer:
        i3.rename__workspace__to('"%d: %s"' % (focused_workspace_num, answer))


if __name__ == '__main__':
    main()

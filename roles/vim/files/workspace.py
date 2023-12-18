#!/usr/bin/env python3

import sys
import os
import subprocess
import argparse
import re
import typing

from subprocess import check_output


def find_dir(path: str) -> str:
    o = check_output(r"find %s -maxdepth 3 -type d \( -name '.*' -prune -o -print \)|cat" % path,
            shell=True)
    return o.decode('utf-8')

def in_tmux():
    return 'TMUX' in os.environ


def in_vim():
    return 'IN_VIM' in os.environ


def fzf(data: bytes, multi: bool = False, filepath: bool = False,
        prompt: str = '>') -> str:
    command = ["fzf", '--prompt=%s' % prompt]
    if multi:
        command.append("-m")
    if filepath:
        command.append("--filepath-word")

    fzf = subprocess.Popen(
        command, stdin=subprocess.PIPE, stdout=subprocess.PIPE)
    stdout_bytes, _ = fzf.communicate(data)
    stdout = stdout_bytes.decode('utf-8').strip()
    return stdout


def choose_one(text: str) -> typing.Tuple[str, str]:
    fzf_args = ['--print-query', '--filepath-word', '--tiebreak=index']
    fzf = None
    if not in_tmux():
        fzf = subprocess.Popen(
            ['fzf'] + fzf_args, stdin=subprocess.PIPE, stdout=subprocess.PIPE)
    else:
        fzf = subprocess.Popen(
            ["fzf-tmux"] + fzf_args, stdin=subprocess.PIPE, stdout=subprocess.PIPE)
    stdout_bytes, _ = fzf.communicate(
        text.encode('utf-8'))
    stdout = stdout_bytes.decode('utf-8')
    if len(stdout) == 0:
        return "", ""
    lst = stdout.split('\n')
    query = lst[0]
    result = ''
    if len(lst) > 1:
        result = lst[1]
    return (query, result)


def list_tmux_window() -> str:
    cmd = ('tmux list-windows -F "#{pane_current_path} #{window_id} '
    '#{window_name} ###{window_index} #{window_activity} aaa:#{window_active} "')
    o = [i.strip() for i in subprocess.check_output(cmd, shell=True).decode("utf-8").strip().split("\n")]
    ret = sorted(o, key=lambda x: x.split(" ")[-2], reverse=True)
    ret = [' '.join(i.split(' ')[:-2]) for i in ret if 'aaa:1' not in i]
    ret = "\n".join(ret)
    ret = ret.replace("&&:0", "")
    return ret.strip()


def cd(a: str, b: str):
    path = a.replace('>cd', '').replace('cd ', '').strip()
    if path == '' or path == 'cd':
        path = os.path.expanduser('~')
    dirs = find_dir(path)
    _, target = choose_one(dirs)
    if target == '':
        return
    if in_vim():
        os.system("tmux new-window -c %s " % target)
    else:
        print(target)


def kill_window(a: str, b: str):
    windows = list_tmux_window()
    chooses = fzf(windows.encode('utf-8'), multi=True)
    for i in chooses.split('\n'):
        if '@' in i:
            win_id = re.findall(r'@\d+', i)[0]
            os.system("tmux kill-window -t %s " % win_id)


def zoxide_list() -> list:
    try:
        output = subprocess.check_output("zoxide query -l", shell=True)
        output = output.decode("utf-8").strip()
        return output.split("\n")
    except Exception:
        return []


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='Process some integers.')
    parser.add_argument('-p', '--print', action='store_true')
    parser.add_argument('dir', metavar='d', type=str, nargs='*')

    args = parser.parse_args()

    paths = [
    ]
    path_file = os.path.expanduser('~/.workspaces')

    if len(args.dir) > 0:
        paths = args.dir
    elif os.path.exists(path_file):
        with open(path_file) as ftr:
            paths = [i.strip() for i in ftr.readlines() if len(i.strip()) > 0]

    chooses = []

    for i in paths:
        i = os.path.expanduser(i)
        if i.endswith('*'):
            i = i[:-1]
            for j in os.listdir(i):
                real_path = os.path.join(i, j)
                if os.path.isdir(real_path):
                    chooses.append(real_path)
        else:
            chooses.append(i)
    chooses += zoxide_list()

    text = '\n>new\n>choose\n>cd\n>kill\n'
    if in_tmux():
        tmux_window = list_tmux_window()
        for i in chooses:
            if i[:-1] not in tmux_window:
                text += i + '\n'
        text = tmux_window + text
    else:
        text = '\n'.join(chooses)
    query, result = choose_one(text.strip())
    result = os.path.expanduser(result)
    command = {
        'new': lambda a, b: os.system('tmux new-window'),
        'choose': lambda a, b: os.system('tmux choose-window'),
        'cd': cd,
        'kill': kill_window,
    }
    if result.startswith('>'):
        command[result[1:]](query, result)
    elif (query.startswith('>cd') or query.startswith('cd')):
        command['cd'](query, result)
    elif len(result.strip()) == 0:
        sys.exit(0)
    elif os.path.exists(result):
        if args.print:
            print(result)
            sys.exit(0)
        os.system("tmux new-window -c %s" % result)
    elif '@' in result:
        win = re.findall(r'@\d+', result)[0]
        os.system("tmux select-window -t %s" % win)
    else:
        sys.exit(0)

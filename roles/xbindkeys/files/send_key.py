#! /usr/bin/env python
import subprocess
import sys
import psutil
import logging


logging.basicConfig(filename='a.log', level='DEBUG')

def get_active_window_id():
    return subprocess.Popen(["xprop", "-root", "_NET_ACTIVE_WINDOW"], stdout=subprocess.PIPE).communicate()[0].strip().split()[-1]

def get_active_window_title():
    return subprocess.Popen(["xprop", "-id", get_active_window_id(), "WM_NAME"], stdout=subprocess.PIPE, stderr=subprocess.PIPE).communicate()[0].strip().split('"', 1)[-1][:-1]

def get_active_window_pid():
    return int(subprocess.Popen(["xprop", "-id", get_active_window_id(), "_NET_WM_PID"], stdout=subprocess.PIPE, stderr=subprocess.PIPE).communicate()[0].strip().split('=', 1)[-1].strip(), 10)


def find_all_subprocess_cmdline(pid):
    process_list = psutil.Process(pid).get_children(recursive=True)
    cmd_list = map(lambda s: ' '.join(s.cmdline()), process_list)
    logging.debug(cmd_list)
    return cmd_list


def send_key_or_not(pattern, pid):
    cmd_list = find_all_subprocess_cmdline(pid)
    for cmd in cmd_list:
        if pattern in cmd:
            return True
    return False


if __name__ == '__main__':
    print get_active_window_pid()
    if len(sys.argv) >= 3:
        title = get_active_window_title()
        pid = get_active_window_pid()
        logging.debug('pattern: %s' % sys.argv[1])
        if send_key_or_not(sys.argv[1], pid):
            subprocess.call(["xvkbd", "-text", sys.argv[2]])
            logging.debug('success')
        logging.debug('end')

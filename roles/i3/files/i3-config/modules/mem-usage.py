# coding=utf-8
from time import time
from subprocess import check_output

def mem_usage():
    with open('/proc/meminfo', 'r') as ftr:
        data = ftr.readlines()
    for i in data:
        if i.strip().startswith('MemTotal'):
            total_mem = int(i.split()[1], 10) / 1024
        elif i.strip().startswith('MemFree'):
            free_mem = int(i.split()[1], 10) / 1024
        elif i.strip().startswith('Cached'):
            cached = int(i.split()[1], 10) / 1024
        elif i.strip().startswith('Buffers'):
            buffers = int(i.split()[1], 10) / 1024
    used = total_mem - free_mem - cached - buffers
    return float(used) * 100 / total_mem


class Py3status:
    """
    Simply output the currently logged in user in i3bar.

    Inspired by i3 FAQ:
        https://faq.i3wm.org/question/1618/add-user-name-to-status-bar/
    """
    def mem_usage(self, i3status_output_json, i3status_config):
        """
        We use the getpass module to get the current user.
        """
        # the current user doesnt change so much, cache it good
        CACHE_TIMEOUT = 600

        raw = mem_usage()
        text = 'Mem: %d%%' % raw

        # set, cache and return the output
        response = {'full_text': text, 'name': 'mem usage'}
        response['cached_until'] = time() + CACHE_TIMEOUT
        return (0, response)

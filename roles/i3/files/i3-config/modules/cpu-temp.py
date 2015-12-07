# coding=utf-8
from time import time
from subprocess import check_output


class Py3status:
    """
    Simply output the currently logged in user in i3bar.

    Inspired by i3 FAQ:
        https://faq.i3wm.org/question/1618/add-user-name-to-status-bar/
    """
    def cpu_temp(self, i3status_output_json, i3status_config):
        """
        We use the getpass module to get the current user.
        """
        # the current user doesnt change so much, cache it good
        CACHE_TIMEOUT = 600

        raw = check_output("sensors|grep 'Core 0'|awk '{print $3 }'", shell=True).strip()
        text = 'CPU: %s' % raw

        # set, cache and return the output
        response = {'full_text': text, 'name': 'cpu-temp'}
        response['cached_until'] = time() + CACHE_TIMEOUT
        return (0, response)

#/usr/bin/env python3
# coding=utf-8
from time import time
from subprocess import check_output


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

        raw = check_output("bash -c 'xprop -id $(xdotool getactivewindow)' | egrep '^WM_NAME'",
                           shell=True).strip()
        fragments = raw.split('=')
        text = '='.join(fragments[1:])[3:-1]

        # set, cache and return the output
        response = {'full_text': text, 'name': 'title'}
        response['cached_until'] = time() + CACHE_TIMEOUT
        return (0, response)

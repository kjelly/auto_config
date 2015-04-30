# -*- coding: utf-8 -*-
from time import time
import requests
import os.path
import os
from subprocess import check_output


CACHE_TIMEOUT = 10


class Py3status:

    def get_battery_status(self):
        info = check_output("upower -d", shell=True).split('\n')
        percentage = ""
        state = ""
        for i in info:
            if "percentage" in i:
                percentage = i.split(' ')[-1]
            if "state" in i:
                state = i.split(' ' )[-1]
        return u"%s: %s" % (state, percentage)

    def battery(self, json, i3status_config):
        """
        This method gets executed by py3status
        """

        response = {
            'cached_until': time() + CACHE_TIMEOUT,
            'full_text': self.get_battery_status(),
            'name': 'weather_yahoo'
            }

        return (0, response)


if __name__ == '__main__':
    a = Py3status()
    print a.get_battery_status()

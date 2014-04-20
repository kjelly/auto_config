# -*- coding: utf-8 -*-
from time import time
import requests
import os.path
import os



i3_user_config_path = os.path.join(os.path.expanduser('~'), '.i3')
weather_data_path = os.path.join(i3_user_config_path,'data',  'W002.txt')
CACHE_TIMEOUT = 3600



class Py3status:
    def get_local_weather(self, local, data):
        for i in data.split(u'\n'):
            if i.find(local) != -1:
                target = i
                break
        return target

    def weather(self, json, i3status_config):
        """
        This method gets executed by py3status
        """
        return (0, {})
        os.system('~/.i3/download_weather_data.py')
        with open(weather_data_path, 'r') as ftr:
            data = ftr.read().decode('big5').encode('utf-8')
        data = unicode(data, 'utf-8')

        local_weather = self.get_local_weather(u'新北市', data)
        colomn = local_weather.split()
        temp_colomn = ''.join(colomn[-3:])
        colomn = colomn[:-3]
        colomn.append(temp_colomn)



        response = {
            'cached_until': time() + CACHE_TIMEOUT,
            'full_text': u','.join(colomn),
            'name': 'weather_yahoo'
            }

        return (0, response)

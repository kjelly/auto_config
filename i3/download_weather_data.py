#! /usr/bin/env python
import os
import os.path
from ftplib import FTP

i3_user_config_path = os.path.join(os.path.expanduser('~'),  '.i3')
i3_data_path = os.path.join(i3_user_config_path,'data')
if not os.path.exists(i3_data_path):
    os.mkdir(i3_data_path)

weather_data_path = os.path.join(i3_data_path,  'W002.txt')

ftp = FTP('ftpsv.cwb.gov.tw')
ftp.login()
ftp.cwd('/pub/forecast/')
with open(weather_data_path, 'w') as f:
    ftp.retrbinary('RETR %s' % 'W002.txt', f.write)
ftp.close()

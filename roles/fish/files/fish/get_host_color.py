#!/usr/bin/env python
import hashlib
import sys
import socket
import getpass
from subprocess import check_output
import tempfile
import os
import pickle


def get_cpu_info():
    with open('/proc/cpuinfo', 'r') as ftr:
        for i in ftr.readlines():
            if 'model name' in i:
                return i

def lspci():
    try:
        return check_output('lspci')
    except Exception as e:
        print(e)
        return ''

def get_all_mac():
    try:
        return check_output('ip l|grep link', shell=True)
    except Exception as e:
        print(e)
        return ''


def main():
    host_color_path = os.path.join(tempfile.gettempdir(), 'host_color')
    update = True
    if os.path.exists(host_color_path):
        try:
            with open(host_color_path, 'r') as ftr:
                data = pickle.load(ftr)
                update = False
        except Exception as e:
            pass
    if update:
        raw_data = socket.gethostname()
        raw_data += getpass.getuser()
        raw_data += get_cpu_info()
        raw_data += lspci()
        raw_data += get_all_mac()
        data = hashlib.sha256(raw_data).digest()[:3]
        data = [ord(i) % 16 for i in data]
        with open(host_color_path, 'w') as ftr:
            pickle.dump(data, ftr)
    if len(sys.argv) > 1:
        data = [15 - i for i in data]
    data = [hex(i)[2:].upper() for i in data]
    output = ''.join(data)
    print(output)


if __name__ == '__main__':
    main()


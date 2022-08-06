#! /usr/bin/python3
from subprocess import check_output
import os
import re


def get_remote_url():
    output = check_output("git remote -v|grep push", shell=True).decode('utf-8')
    return output


def get_username_and_repository_from_http_url(url):
    result = re.search(r'https://github.com/(?P<username>\w+)/(?P<respository>(\w|[\-_])+)(\.git)?', url)
    if result:
        return result.groupdict()
    ret = {}
    ret['username'] = input("Please input your user name.")
    ret['respository'] = input("Please input your respository name.")
    return ret


url = get_remote_url()
git_info = get_username_and_repository_from_http_url(url)
os.system("git remote set-url --push origin git@github.com:%s/%s.git" % (git_info['username'], git_info['respository']))

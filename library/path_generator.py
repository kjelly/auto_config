#!/usr/bin/python
from ansible.module_utils.basic import *
import os


def get_go_root_bin():
    goroot = os.getenv('GOROOT', None)
    if goroot:
        goroot_bin = os.path.join(goroot, 'bin')
        if os.path.exists(goroot_bin):
            return goroot_bin
    return ''


def main():
    module = AnsibleModule(argument_spec={})

    env_path = []

    path_list = ['~/gohome/bin', '~/bin', '~/mybin', '~/dark-sdk/bin',
                 '~/swif/usr/bin', '/usr/local/mercury-14.01.1/bin']

    for path in path_list:
        real_path = os.path.abspath(os.path.expanduser(path))
        if os.path.exists(real_path):
            env_path.append(real_path)

    goroot_bin = get_go_root_bin()
    if goroot_bin != '':
        env_path.append(goroot_bin)

    module.exit_json(changed=False, ENV_PATH=' '.join(env_path))


if __name__ == '__main__':
    main()


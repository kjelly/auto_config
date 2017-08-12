#!/usr/bin/python
from ansible.module_utils.basic import *
import os
import glob


def get_go_root_bin():
    goroot = os.getenv('GOROOT', None)
    if goroot:
        goroot_bin = os.path.join(goroot, 'bin')
        if os.path.exists(goroot_bin):
            return goroot_bin
    return ''


def get_real_path(path):
    if path[0] == '~':
        home = os.path.expanduser("~")
        path = os.path.join(home, path[2:])

    path_list = glob.glob(path)
    if len(path_list) == 0:
        return ''
    else:
        return os.path.realpath(path_list[0])


def main():
    module = AnsibleModule(argument_spec={})

    env_path = []

    path_list = ['~/gohome/bin', '~/bin', '~/mybin', '~/dark-sdk/bin',
                 '~/swif/usr/bin', '/usr/local/mercury-14.01.1/bin',
                 '/usr/lib/dart/bin/', '~/.cargo/bin/', '~/sbt/bin',
                 '~/.pub-cache/bin', '~/dart-sdk/bin', '~/activator/bin/',
                 '~/google-cloud-sdk/bin/']

    for path in path_list:
        real_path = os.path.abspath(os.path.expanduser(path))
        if os.path.exists(real_path):
            env_path.append(real_path)

    goroot_bin = get_go_root_bin()
    if goroot_bin != '':
        env_path.append(goroot_bin)

    node_bin = get_real_path("/home/kjelly/node*/bin")
    node_bin = get_real_path("~/node*/bin")
    if node_bin:
        env_path.append(node_bin)

    module.exit_json(changed=False, ENV_PATH=' '.join(env_path))


if __name__ == '__main__':
    main()


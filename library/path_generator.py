#!/usr/bin/python
import glob
import os
from ansible.module_utils.basic import AnsibleModule


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
    path_list = sorted(path_list, reverse=True)
    return os.path.realpath(path_list[0])


def main():
    module_args = dict(
        shell=dict(type='str', required=False),
        bin=dict(type='str', required=False),
    )
    module = AnsibleModule(argument_spec=module_args)

    env_path = []

    path_list = ['~/gohome/bin', '~/bin', '~/mybin', '~/dark-sdk/bin',
                 '~/swif/usr/bin', '/usr/local/mercury-14.01.1/bin',
                 '/usr/lib/dart/bin/', '~/.cargo/bin/', '~/sbt/bin',
                 '~/.pub-cache/bin', '~/dart-sdk/bin', '~/activator/bin/',
                 '~/google-cloud-sdk/bin/', '~/kotlinc/bin/', '~/.rvm/bin',
                 '/snap/bin/', '~/flutter/bin/', '~/.local/bin', '~/.deno/bin/',
                 '~/flutter/bin/cache/dart-sdk/bin',
                 '~/nfs/bin/', '~/.pub-cache/bin', '~/anaconda3/bin/']

    fuzzy_path = ['~/node*/bin', '~/.asdf/installs/python/*/bin', '~/pypy*/bin/']

    for path in path_list:
        real_path = os.path.abspath(os.path.expanduser(path))
        if os.path.exists(real_path):
            env_path.append(real_path)

    goroot_bin = get_go_root_bin()
    if goroot_bin != '':
        env_path.append(goroot_bin)

    for i in fuzzy_path:
        path = get_real_path(i)
        if path:
            env_path.append(path)

    if module.params['shell'] == 'fish':
        module.exit_json(changed=False, ENV_PATH=' '.join(env_path))
    if module.params['shell'] == 'nushell':
        module.exit_json(changed=False, ENV_PATH=env_path)
    else:
        module.exit_json(changed=False, ENV_PATH=':'.join(env_path))


if __name__ == '__main__':
    main()

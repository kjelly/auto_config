#! /usr/bin/env python
import argparse
import getpass
import os
import os.path


def find_base_dir():
    return os.path.realpath(os.path.dirname(__file__))


def main():
    base_dir = find_base_dir()
    inventory_path = os.path.join(base_dir, 'hosts')
    parser = argparse.ArgumentParser(description='deploy script')
    parser.add_argument('-i', '--inventory', type=str, default=inventory_path)
    parser.add_argument('-p', '--playbook', type=str, required=True)
    parser.add_argument('--host', type=str, default='local')
    parser.add_argument('-a', '--action', type=str,
                        default='config', choices=['config', 'deploy'])
    parser.add_argument('-u', '--user', type=str, default=getpass.getuser())
    parser.add_argument('--sudo', type=bool)

    args, unknown = parser.parse_known_args()
    print(args)
    print(unknown)

    data = {
        'user': args.user,
        'action': args.action,
        'playbook': args.playbook,
        'inventory': args.inventory
    }
    sudo = ''

    if args.host == 'local':
        data['group'] = 'local'
        data['remote_host'] = None
    else:
        data['group'] = 'remote'
        data['remote_host'] = args.host
    if args.sudo:
        sudo = 'sudo -E -P -u {user} '
    cmd = ((sudo + '''ansible-playbook -i "{inventory}" '''
           '''"{playbook}" -e ansible_user="{user}" -e group="{group}" '''
           '''-e remote_host="{remote_host}" -e action="{action}" '''
           ''' -vvvv ''').format(
               **data) + ' '.join(unknown))
    print(cmd)
    os.system(cmd)

if __name__ == '__main__':
    main()

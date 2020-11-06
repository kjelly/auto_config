#! /usr/bin/env python
import os
import os.path
import json
import sys


def get_database_path():
    return os.path.expanduser('~/.p/database')


def read_data(path):
    if not os.path.exists(path):
        return {}
    with open(path, 'r') as ftr:
        return json.load(ftr)


def write_data(path, data):
    if not os.path.exists(os.path.dirname(path)):
        os.makedirs(os.path.dirname(path))
    with open(path, 'w') as ftr:
        json.dump(data, ftr, sort_keys=True, indent=4, separators=(',', ': '))



def show(key):
    database_path = get_database_path()
    data = read_data(database_path)
    print(data.get(key, {}).get('value', ''))


def list_key_value():
    database_path = get_database_path()
    data = read_data(database_path)
    print(json.dumps(data, sort_keys=True, indent=4, separators=(',', ': ')))


def delete_key(key):
    database_path = get_database_path()
    data = read_data(database_path)
    del data[key]
    write_data(database_path, data)


def set_key_value(key, value, comment=''):
    database_path = get_database_path()
    data = read_data(database_path)
    data[key] = {'value': value, 'comment': comment}
    write_data(database_path, data)


action_map = {'-s': set_key_value, '-l': list_key_value, '-d': delete_key,
              '': show}


def get_element_from_list(index, lst):
    if index >= len(lst):
        return ''
    return lst[index]


def get_command_from_argv(argv):
    action = argv[0]
    if action in action_map:
        argv = argv[1:]
    else:
        action = ''
    return action, argv



def main():
    system_argv = sys.argv[1:]
    action, args = get_command_from_argv(system_argv)
    action_map.get(action, show)(*args)


if __name__ == '__main__':
    main()

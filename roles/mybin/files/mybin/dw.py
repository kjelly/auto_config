#! /usr/bin/env python
import sys
import os
import readline
import cmd
import functools

import docker


c = docker.Client(base_url='unix://var/run/docker.sock',
                  version='1.6',
                  timeout=10)


class CustomDockerCommand(object):

    @staticmethod
    def remove_all_container():
        cmd = "sudo docker rm `docker ps -notrunc -a -q`"
        if raw_input("Are you sure? [y/N]") == 'y':
            os.system(cmd)

    @classmethod
    def get_custom_command_list(cls):
        exclude = ['get_custom_command_list', '__weakref__']
        return list(set(dir(cls)) - set(dir(type) + exclude))


cmd_list = ["attach", "build", "commit", "cp", "diff",
            "events", "export", "histor", "images", "import",
            "info", "insert", "inspec", "kill", "load", "login",
            "logs", "port", "ps", "pull", "push", "restar", "rm",
            "rmi", "run", "save", "search", "start", "stop", "tag",
            "top", "version", "wait"] + ['shell'] + CustomDockerCommand.get_custom_command_list()


def run_cmd(text, cmd):
    if cmd == 'start':
        start_wrapper(text.split(' '))
    else:
        os.system('sudo docker %s %s' % (cmd, text))


def complete_cmd(text, line, start_index, end_index, cmd):
    container_list, name_map = get_all_id_or_name()
    results = filter(lambda s: s[:len(text)] == text, container_list)
    return results


class DockerShellMeta(type):
    def __new__(cls, cls_name, bases, attrs):
        for i in cmd_list:
            if i == 'shell':
                continue
            elif i in CustomDockerCommand.get_custom_command_list():
                attrs['do_' + i] = lambda *args:getattr(CustomDockerCommand, i)()
                continue
            if i != 'shell':
                attrs['do_' + i] = functools.partial(run_cmd, cmd=i)
                attrs['complete_' + i] = functools.partial(complete_cmd, cmd=i)
        return super(DockerShellMeta, cls).__new__(cls, cls_name, bases, attrs)


class DockerShell(cmd.Cmd):
    __metaclass__ = DockerShellMeta
    prompt = '(docker) : '

    def do_quit(self, text):
        sys.exit(0)


def split_port(port):
    if ':' in port:
        guest, host = port.split(':')
        return {int(guest): int(host)}
    return {int(port): None}


def start_wrapper(argv):
    index = 0
    port_list = []
    args = []

    while index < len(argv):
        if argv[index] == '-p':
            port_list.append(argv[index + 1])
            index += 2
        else:
            args.append(argv[index])
            index += 1
    if len(args) == 0:
        raise ValueError("Not enough arguments for start")
    port_list = map(split_port, port_list)
    port_map = {}
    for i in port_list:
        port_map.update(i)
    start(port=port_map, *args)
    return 'success'


def find_one(pattern, lst):
    results = filter(lambda s: s[:len(pattern)] == pattern, lst)
    length = len(results)
    if length == 0:
        raise ValueError("Not found")
    elif length > 1:
        print results
        raise ValueError("Too many match")
    return results[0]


def get_all_id_or_name():
    data = c.containers(all=True)
    id_list = map(lambda s: s['Id'], data)
    name_list = map(lambda s: s['Names'], data)
    lst = id_list
    for i in name_list:
        lst.extend(i)
    name_map = {}
    for container in data:
        id = container['Id']
        for name in container['Names']:
            name_map[name] = id
    return lst, name_map


def start(id, port=None):
    container_list, name_map = get_all_id_or_name()
    if not container_list:
        print 'Not found'
        return
    result = find_one(id, container_list)
    if len(port) == 0:
        port = None
    if id[0] == '/':
        result = name_map.get(result, result)
    c.start(result, port_bindings=port)





def main():
    argv = sys.argv
    if os.geteuid() != 0:
        os.system('sudo python %s' % ' '.join(argv))
        return
    if len(argv) == 1:
        print 'default', argv
        os.system("sudo docker")
        return
    cmd = argv[1] = find_one(argv[1], cmd_list)
    if cmd == 'start':
        start_wrapper(argv[2:])
    if argv[1] == 'shell':
        shell = DockerShell()
        shell.cmdloop()
    elif cmd in CustomDockerCommand.get_custom_command_list():
        getattr(CustomDockerCommand, cmd)()
    else:
        cmd = "sudo docker %s" % ' '.join(argv[1:])
        print cmd
        os.system(cmd)


if __name__ == '__main__':
    main()

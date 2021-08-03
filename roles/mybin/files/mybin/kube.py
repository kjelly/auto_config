#!/usr/bin/env python3
import os
import subprocess
import re
import argparse
from subprocess import check_output

KUBE_HELP = '''
create        Create a resource from a file or from stdin.
expose        Take a replication controller, service, deployment or pod and expose it as a new Kubernetes Service
get           Display one or many resources
edit          Edit a resource on the server
delete        Delete resources by filenames, stdin, resources and names, or by resources and label selector
scale         Set a new size for a Deployment, ReplicaSet or Replication Controller
autoscale     Auto-scale a Deployment, ReplicaSet, StatefulSet, or ReplicationController
cluster-info  Display cluster info
top           Display Resource (CPU/Memory) usage.
cordon        Mark node as unschedulable
uncordon      Mark node as schedulable
drain         Drain node in preparation for maintenance
taint         Update the taints on one or more nodes
describe      Show details of a specific resource or group of resources
logs          Print the logs for a container in a pod
attach        Attach to a running container
exec          Execute a command in a container
port-forward  Forward one or more local ports to a pod
proxy         Run a proxy to the Kubernetes API server
cp            Copy files and directories to and from containers.
debug         Create debugging sessions for troubleshooting workloads and nodes
diff          Diff live version against would-be applied version
apply         Apply a configuration to a resource by filename or stdin
patch         Update field(s) of a resource
replace       Replace a resource by filename or stdin
kustomize     Build a kustomization target from a directory or URL.
label         Update the labels on a resource
annotate      Update the annotations on a resource
'''


class bcolors:
    HEADER = '\033[95m'
    OKBLUE = '\033[94m'
    OKCYAN = '\033[96m'
    OKGREEN = '\033[92m'
    WARNING = '\033[93m'
    FAIL = '\033[91m'
    ENDC = '\033[0m'
    BOLD = '\033[1m'
    UNDERLINE = '\033[4m'


def fzf(data: bytes, multi: bool = False, filepath: bool = False,
        prompt: str = '>') -> str:
    command = ["fzf", '--prompt=%s' % prompt]
    if multi:
        command.append("-m")
    if filepath:
        command.append("--filepath-word")

    fzf = subprocess.Popen(
        command, stdin=subprocess.PIPE, stdout=subprocess.PIPE)
    stdout_bytes, stderr_bytes = fzf.communicate(data)
    stdout = stdout_bytes.decode('utf-8').strip()
    return stdout


def fzf_file(path: str, prompt: str = '>'):
    found = False
    while not found:
        os.chdir(path)
        lst = [i if os.path.isfile(i) else i + '/' for i in os.listdir('.')]
        path = fzf(('..\n' + '\n'.join(lst)).encode('utf-8'),
                   filepath=True, prompt=prompt).strip()
        if os.path.isfile(path) or path == '':
            found = True
    print(path)
    return path


def fzf_dir(path: str):
    found = False
    while not found:
        os.chdir(path)
        dirs = check_output(r"find . -type d -not -path '*/\.*'",
                            shell=True).decode('utf-8')
        dirs = '..\n' + dirs
        path = fzf(dirs.encode('utf-8'), filepath=True)
        if path != '..' or path == '':
            found = True
    print(path)
    return path


def select_namespace():
    namespaces = check_output('kubectl get namespace -o custom-columns=NAMESPACE:.metadata.name',
                              shell=True)
    namespaces = namespaces.replace(b'NAMESPACE\n', b'')
    return fzf(namespaces)


def copy_to_clipboard(command: str, data: str):
    copy = subprocess.Popen(
        command, stdin=subprocess.PIPE, stdout=subprocess.PIPE)
    stdout, stderr = copy.communicate(data.encode('utf-8'))
    print(stdout.decode('utf-8'))


def main():
    parser = argparse.ArgumentParser(description='Kubenetes helper')
    parser.add_argument('-p', '--print-only', action='store_true')
    parser.add_argument('-s', '--show-help', action='store_true')
    parser.add_argument('-c', '--copy', action='store_true')
    parser.add_argument('--copy-command', type=str, default='hterm-copy')
    parser.add_argument('command', type=str, nargs='*')

    args = parser.parse_args()
    print_only = args.print_only
    copy = args.copy
    copy_command = args.copy_command
    show_help = args.show_help
    print_only_command_list = ['autoscale', 'exec', 'cp',
                               'patch', 'label', 'annotate', 'scale',
                               'debug']
    command = ''
    full_command_list = []
    if len(args.command) > 0:
        command = args.command[0]
    else:
        choose: str = fzf(KUBE_HELP.strip().encode('utf-8'))
        command = re.split(' +', choose)[0].strip()
    if(command == ''):
        return
    if command in ['create', 'apply', 'diff', 'replace']:
        full_command_list.append(command_with_file(command))
    elif command in ['cluster-info']:
        full_command_list.append('kubectl cluster-info')
    else:
        full_command_list.extend(
            command_with_resource(command, not print_only))
    if command in print_only_command_list:
        print_only = True
    copy_data = ''
    last_full_command = ''
    for full_command in full_command_list:
        if print_only:
            print(full_command)
            copy_data += full_command + '\n'
            last_full_command = full_command
        else:
            print(bcolors.WARNING + full_command + bcolors.ENDC)
            os.system(full_command)
            print()
    if show_help:
        os.system(last_full_command + ' --help')
    if copy:
        copy_to_clipboard(copy_command, copy_data)


def command_with_file(command):
    namespace = select_namespace()
    if namespace == '':
        return
    full_command = 'kubectl {command} -n {namespace} '.format(
        command=command, namespace=namespace)
    count = 1
    while True:
        f = fzf_file('.', prompt='file %d' % count)
        if f == '':
            break
        count += 1
        full_command += '-f %s' % f
    return full_command


def command_with_resource(command: str, multi: bool = False) -> list:
    resources = check_output("kubectl get all,node -o "
                             "custom-columns=NAME:.metadata.name,"
                             "KIND:.kind,NAMESPACE:.metadata.namespace "
                             "--all-namespaces", shell=True)
    resources = '\n'.join([i for i in resources.decode('utf-8').split('\n')
                           if 'NAME' not in i]).encode('utf-8')

    choose: str = fzf(resources, multi=multi)
    if choose == '':
        return []
    ret = []
    for item in choose.split('\n'):
        name, kind, namespace = re.split(' +', item)
        full_command = ('kubectl {command} {kind}/{name} '.
                        format(kind=kind,
                               name=name, command=command))
        if namespace != '<none>':
            full_command += ' -n %s ' % namespace
        ret.append(full_command)
    return ret


if __name__ == '__main__':
    main()

#!/usr/bin/env python3

import argparse
import os


def create_container(name: str, os_version: str):
    home = os.environ.get("HOME")
    command = f"""
mkdir -p {home}/fake-home
lxc network set lxdbr0 raw.dnsmasq dhcp-option=6,8.8.8.8,8.8.4.4
lxc launch {os_version} {name}
lxc config device add {name} myhomedir disk source={home}/fake-home path=/home/ubuntu
lxc config set {name} raw.idmap "both 1000 1000"
lxc restart {name}
sleep 2s
lxc exec {name} --user 0 -- bash -c 'sudo apt update;sudo apt install -y fish zsh'
    """
    print(command)
    os.system(command)


def enter_shell(name):
    command = f"""
lxc exec {name} --user 1000 --cwd /home/ubuntu/  --env HOME=/home/ubuntu -- fish
    """
    os.system(command)


def delete_container(name, force=False):
    command = f"lxc delete {name}"
    if force:
        command += " --force"
    os.system(command)


def list_container():
    command = "lxc list"
    os.system(command)


def main():
    parser = argparse.ArgumentParser(description="deploy script")
    subparsers = parser.add_subparsers(help="subcommand", dest="subcommand")
    list_parser = subparsers.add_parser("list")
    list_parser.add_argument("a", nargs="*")
    create_parser = subparsers.add_parser("create")
    create_parser.add_argument("name")
    create_parser.add_argument("-o", "--os", type=str, default="ubuntu:20.04")
    delete_parser = subparsers.add_parser("delete")
    delete_parser.add_argument("name")
    delete_parser.add_argument("-f", "--force", action="store_true")
    shell_parser = subparsers.add_parser("shell")
    shell_parser.add_argument("name")

    args, _ = parser.parse_known_args()
    if args.subcommand in ["list"]:
        list_container()
    elif args.subcommand in ["create"]:
        create_container(args.name, args.os)
    elif args.subcommand in ["shell"]:
        enter_shell(args.name)
    elif args.subcommand in ["delete"]:
        delete_container(args.name, force=args.force)


if __name__ == "__main__":
    main()

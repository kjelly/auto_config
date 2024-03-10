#!/usr/bin/env python3

import argparse
import glob
import os
import subprocess


def get_real_path(path):
    if path[0] == "~":
        home = os.path.expanduser("~")
        path = os.path.join(home, path[2:])

    path_list = glob.glob(path)
    if len(path_list) == 0:
        return ""
    path_list = sorted(path_list, reverse=True)
    return os.path.realpath(path_list[0])


def update_env():
    path_list = [
        "~/gohome/bin",
        "~/bin",
        "~/mybin",
        "~/dark-sdk/bin",
        "~/swif/usr/bin",
        "/usr/local/mercury-14.01.1/bin",
        "/usr/lib/dart/bin/",
        "~/.cargo/bin/",
        "~/sbt/bin",
        "~/.pub-cache/bin",
        "~/dart-sdk/bin",
        "~/activator/bin/",
        "~/google-cloud-sdk/bin/",
        "~/kotlinc/bin/",
        "~/.rvm/bin",
        "/snap/bin/",
        "~/flutter/bin/",
        "~/.local/bin",
        "~/.deno/bin/",
        "~/flutter/bin/cache/dart-sdk/bin",
        "~/nfs/bin/",
        "~/.pub-cache/bin",
        "~/anaconda3/bin/",
    ]

    fuzzy_path = [
        "~/node*/bin",
        "~/.asdf/installs/python/*/bin",
        "~/pypy*/bin/",
        "~/go*/bin/",
    ]
    env_path = []
    for path in path_list:
        real_path = os.path.abspath(os.path.expanduser(path))
        if os.path.exists(real_path):
            env_path.append(real_path)

    for i in fuzzy_path:
        path = get_real_path(i)
        if path:
            env_path.append(path)
    os.environ["PATH"] = ":".join(env_path) + os.environ["PATH"]


def list_all_sessions():
    ret = []
    try:
        output = subprocess.check_output(["tmux", "ls"]).decode("utf-8")
        lines = output.strip().split("\n")
        for i in lines:
            session_name = i.split(":")[0]
            ret.append(session_name)

    except subprocess.CalledProcessError:
        pass
    return ret


def main():
    parser = argparse.ArgumentParser(description="Tmux wrapper")
    parser.add_argument("name", type=str, nargs="?")
    parser.add_argument("--list", "-l", action="store_true")
    parser.add_argument("--kill", "-k")
    args = parser.parse_args()
    session_list = list_all_sessions()
    tmux = "tmux"
    os.chdir(os.path.expanduser("~"))
    update_env()
    if args.list:
        print(session_list)
        return
    elif args.kill is not None:
        os.system("%s kill-session -t %s" % (tmux, args.kill))
    elif args.name is None:
        os.system("%s attach #" % (tmux))
    else:
        name = args.name
        if name in session_list:
            os.system("%s attach -t %s" % (tmux, name))
        else:
            os.system("%s new -s %s" % (tmux, name))


if __name__ == "__main__":
    main()

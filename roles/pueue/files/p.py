#!/usr/bin/env python3
import argparse
import os
from subprocess import Popen, PIPE, check_output
import json
import readline
from itertools import groupby

histfile = os.path.join(os.path.expanduser("~"), ".python_history")
script_path = os.path.realpath(__file__)


def pueue_status():
    return json.loads(check_output([
        "pueue", "status", "-j"]).decode("utf-8"))


def get_latest_task_id():
    latest_date = ''
    latest_id = ''
    dct = pueue_status()
    tasks = dct["tasks"]
    for i in tasks:
        obj = tasks[i]
        if obj["start"] is None:
            continue
        if obj["start"] > latest_date:
            latest_date = obj["start"]
            latest_id = i
    return latest_id


def fzf(items):
    with Popen(["fzf"], stdin=PIPE, stdout=PIPE) as proc:
        stdout, _ = proc.communicate("\n".join(items).encode("utf-8"))
        proc.wait()
        return stdout.decode("utf-8").strip()


def shell(history):
    readline.parse_and_bind('tab: complete')
    readline.parse_and_bind('set editing-mode vi')
    for i in history:
        readline.add_history(i)
    while True:
        try:
            line = input('Prompt ("stop" to quit): ')
            if line == 'stop':
                break
            os.system(f"{script_path} {line}")
            readline.add_history(line)
        except KeyboardInterrupt:
            print('')


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--p-delay", type=str, default="1")
    args, rest = parser.parse_known_args()
    delay = args.p_delay
    if not rest:
        os.system("pueue")
        return
    home = os.environ["HOME"]
    config_path = f"{home}/.p"
    config = {}
    if os.path.exists(config_path):
        try:
            with open(config_path, "r", encoding='utf-8') as ftr:
                config = json.load(ftr)
        except ValueError:
            pass
    if "history" not in config:
        config["history"] = []

    command = rest[0]
    if command in ["follow", "add", "clean", "remove",
                   "restart", "kill", "pause", "log", "wait"]:
        os.system(f"pueue {command} {' '.join(rest[1:])}")
    elif command in ["restart", "follow", "remove", "kill", "pause", "start"]:
        if len(rest) == 1:
            latest_id = get_latest_task_id()
            os.system(f"pueue {command} {latest_id}")
        else:
            os.system(f"pueue {command} {' '.join(rest[1:])}")
    elif command == "fl":
        latest_id = get_latest_task_id()
        os.system(f"pueue follow {latest_id}")
    elif command == "f":
        if len(rest) == 1:
            os.system("pueue follow")
        elif rest[1] in ["-1", ":"]:
            latest_id = get_latest_task_id()
            os.system(f"pueue follow {latest_id}")
        else:
            os.system(f"pueue follow {' '.join(rest[1:])}")

    elif command == "fzf":
        history = [' '.join(i) for i in config["history"]]
        print(fzf(history))
    elif command == "shell":
        history = [' '.join(i) for i in config["history"]]
        shell(history)
    else:
        commands = [list(group) for k, group in groupby(rest, lambda x: x == "--")
            if not k]
        config["history"].append(commands[0])
        with Popen(["pueue", "add", "-p", "-d", delay,*commands[0]],
                   stdout=PIPE, stderr=PIPE) as proc:
            proc.wait()
            # assert proc.stdout is not None
            stdout, _ = proc.communicate()
            task_id = stdout.decode("utf-8").strip()
        first_task_id = task_id
        for command in commands[1:]:
            with Popen(["pueue", "add", "-a", task_id, "-p",
                        *command], stdout=PIPE, stderr=PIPE) as proc:
                proc.wait()
                assert proc.stdout is not None
                task_id = proc.stdout.readline().decode("utf-8").strip()
        tasks = pueue_status()["tasks"]
        if first_task_id in tasks and tasks[first_task_id]["start"]:
            os.system(f"pueue follow {first_task_id}")

    with open(config_path, "w", encoding='utf=8') as ftr:
        json.dump(config, ftr)


if __name__ == "__main__":
    main()

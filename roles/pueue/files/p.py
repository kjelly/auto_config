#!/usr/bin/env python3
import time
import argparse
import os
from subprocess import Popen, PIPE
import json
import readline
import atexit

histfile = os.path.join(os.path.expanduser("~"), ".python_history")
script_path = os.path.realpath(__file__)


def fzf(items):
    p = Popen(["fzf"], stdin=PIPE, stdout=PIPE)
    stdout, _ = p.communicate("\n".join(items).encode("utf-8"))
    p.wait()
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


def shell1():
    rl = readline.get_instance()
    rl.set_prompt('>>> ')
    while True:
        try:
            line = rl.readline()
            if line == 'stop':
                break
            os.system(f"{script_path} {line}")
        except KeyboardInterrupt:
            print('')


def main():
    parser = argparse.ArgumentParser()
    args, rest = parser.parse_known_args()
    if not rest:
        os.system("pueue")
        return
    home = os.environ["HOME"]
    config_path = f"{home}/.p"
    config = {}
    if os.path.exists(config_path):
        try:
            with open(config_path, "r") as f:
                config = json.load(f)
        except:
            pass
    if "history" not in config:
        config["history"] = []

    command = rest[0]
    if command in ["follow", "add", "clean",
                   "restart", "kill", "pause", "log", "wait"]:
        os.system(f"pueue {command} {' '.join(rest[1:])}")
    elif command == "fzf":
        history = [' '.join(i) for i in config["history"]]
        print(fzf(history))
    elif command == "shell":
        history = [' '.join(i) for i in config["history"]]
        shell(history)
    else:
        config["history"].append(rest)
        p = Popen(["pueue", "add", *rest], stdout=PIPE, stderr=PIPE)
        p.wait()
        task_id = p.stdout.readline().decode("utf-8")[19:-3]
        time.sleep(1)
        os.system(f"pueue follow {task_id}")

    with open(config_path, "w") as f:
        json.dump(config, f)


if __name__ == "__main__":
    main()

#! /usr/bin/env python3
import argparse
import getpass
import json
import os
import os.path
import select
import sys
import tempfile
from contextlib import suppress


def find_base_dir():
    return os.path.realpath(os.path.dirname(__file__))


def main():
    base_dir = find_base_dir()
    inventory_path = os.path.join(base_dir, "hosts")
    parser = argparse.ArgumentParser(description="deploy script")
    parser.add_argument("-i", "--inventory", type=str, default=inventory_path)
    parser.add_argument("--host", type=str, default="local")
    parser.add_argument("-a", "--action", type=str, default="config")
    parser.add_argument("-u", "--user", type=str, default=getpass.getuser())
    parser.add_argument("--sudo", action="store_true", default=False)
    parser.add_argument("--role", "-r", nargs="+", required=True)

    args, unknown = parser.parse_known_args()
    print(args)
    print(unknown)

    data = {
        "user": args.user,
        "action": args.action,
        "inventory": args.inventory,
        "roles": args.role,
        "programming": True,
    }
    sudo = "sudo -E -P -u {user} " if args.sudo else ""

    if args.host == "local":
        data["group"] = "local"
        data["remote_host"] = None
    else:
        data["group"] = "remote"
        data["remote_host"] = args.host

    stdin_data = {}
    with suppress(Exception):
        if select.select(
            [
                sys.stdin,
            ],
            [],
            [],
            0.0,
        )[0]:
            stdin_data = json.loads(sys.stdin.read())

    data.update(stdin_data)
    print(data)

    playbook_dict = [
        {
            "name": "install",
            "remote_user": data["user"],
            "hosts": data["group"],
            "vars": {"programming": data["programming"], "group": data["group"]},
            "roles": data["roles"],
        }
    ]

    f = tempfile.NamedTemporaryFile(delete=False, prefix="auto_config")
    f.write(json.dumps(playbook_dict).encode("utf-8"))
    f.flush()

    data["playbook"] = f.name

    cmd = (
        sudo + """ansible-playbook -i "{inventory}" """
        """"{playbook}" -e ansible_user="{user}" -e group="{group}" """
        """-e remote_host="{remote_host}" -e action="{action}" """
        """ """
    ).format(**data) + " ".join(unknown)
    print(cmd)

    os.system(cmd)

    f.close()
    return


if __name__ == "__main__":
    main()

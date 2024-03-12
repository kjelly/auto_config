#!/usr/bin/env python3
from subprocess import check_output


def parse(text):
    ret = {}
    for i in text.strip().split("\n"):
        a, b = i.split("=", 1)
        ret[a] = b
    return ret


def main():
    units = ["run"] + [f"run{i}" for i in range(1, 6)]
    info = [
        parse(check_output(f"systemctl --user show {i} ", shell=True).decode("utf-8"))
        for i in units
    ]
    # info = [i for i in info if i.get("ExecStart", "") != ""]
    icon_map = {"activating": "🟢", "inactive": "🟪", "failed": "❌"}
    info = [f"{icon_map.get(i.get('ActiveState'))}" for i in info]
    info = "".join(info)
    step = 5
    info = [info[i : i + step] for i in range(0, len(info), 5)]
    text = f"{info[0]},{info[1]}"
    print(text)


if __name__ == "__main__":
    main()

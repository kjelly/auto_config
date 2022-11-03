#!/usr/bin/env python3

from contextlib import suppress
from subprocess import check_output
import os
import shlex


template = '''
@font-face {
  font-family: %s;
  src: url("%s");
}
'''


def get_value(v):
    first = v.index('"')
    second = v.index('"', first + 1)
    return v[first + 1:second]


def get_font_family(path: str):
    path = shlex.quote(path)
    output = check_output(
        f"fc-scan {path}", shell=True).decode('utf-8').strip()
    dct = {}
    for i in output.split("\n"):
        if ":" not in i:
            continue
        parts = i.split(":")
        dct[parts[0].strip()] = ':'.join(parts[1:])
    style = get_value(dct["style"])
    if style not in ["Regular", "Medium", "Book"]:
        raise ValueError("Not good font")
    family = dct["family"]
    return get_value(family)


def main():
    os.chdir("/opt/fonts")
    files = os.listdir(".")
    for i in files:

        with suppress(Exception):
            lower = i.lower()
            if 'Mono' not in i:
                continue
            if ('window' in lower or 'italic' in lower or 'bold' in lower
                    or 'extra' in lower or 'thin' in lower or 'medium' in lower or 'retina' in lower):
                continue
            family = get_font_family(i)
            if 'Nerd Font Mono' not in family:
                continue
            print(template % (family, i))


if __name__ == '__main__':
    main()

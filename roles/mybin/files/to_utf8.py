#! /usr/bin/env python
from subprocess import check_output
import sys


def detect_codec(name):
    output = check_output('enca -L zh "%s"' % name, shell=True)
    lst = output.split('\n')
    return lst[0].split(';')[1].strip()

def to_utf8(name, source_codec):
    output = check_output('iconv -f "{0}" -t utf-8 "{1}" -o "{1}.utf8.srt"'.format(source_codec, name), shell=True)
    print output


if __name__ == '__main__':
    name = sys.argv[1]
    codec = detect_codec(name)
    to_utf8(name, codec)


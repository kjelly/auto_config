#!/usr/bin/env python
import hashlib
import sys


def main():
    data = hashlib.sha256(sys.argv[1]).digest()[:3]
    data = [ord(i) % 16 for i in data]
    if len(sys.argv) > 2:
        data = [i^15 for i in data]
    if data[0] < 5 and data[1] < 5 and data[2] < 5:
        data[0] += 4
    data = [hex(i)[2:].upper() for i in data]
    print(''.join(data))


if __name__ == '__main__':
    main()


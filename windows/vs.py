#!/usr/bin/env python

import os
import os.path
import sys

path = os.path.abspath(sys.argv[1])

path = path.replace("/mnt/c/", "c:\\").replace("/", "\\")

os.system("code '%s'" % path)

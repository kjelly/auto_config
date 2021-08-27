#!/usr/bin/env python3
import json
import sys


print(json.dumps(json.load(sys.stdin),
                 ensure_ascii=False, indent=4, sort_keys=True))

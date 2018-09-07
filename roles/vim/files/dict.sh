#!/bin/bash

echo "wrod: $1"
w3m -no-cookie "http://cdict.info/query/$1"|grep -A 199 "結果"

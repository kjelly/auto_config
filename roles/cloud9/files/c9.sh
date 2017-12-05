#!/bin/bash
workspace=$1
shift
~/c9sdk/server.js -p 7777 -w $workspace $@;
#/usr/bin/node /opt/c9sdk/server.js --listen 0.0.0.0 -p 7777 -w $1 -a :;

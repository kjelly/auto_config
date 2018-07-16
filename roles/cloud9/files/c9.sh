#!/bin/bash
workspace=$1
shift
~/c9sdk/server.js -w $workspace $@;
#~/c9sdk/server.js --listen 0.0.0.0 -w $workspace $@ -a :;

#!/bin/bash

lxc exec $1 --user 0 -- bash -c 'mkdir /workspace;chown 1000:1000 /workspace'
lxc exec $1 --user 1000 --cwd /workspace/  --env HOME=/home/ubuntu -- bash

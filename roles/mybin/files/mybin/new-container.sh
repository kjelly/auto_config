#!/bin/bash
mkdir -p ${HOME}/fake-home
lxc launch $1 $2
lxc config device add $2 myhomedir disk source=${HOME}/fake-home path=/home/ubuntu
lxc config set $2 raw.idmap "both 1000 1000"
lxc restart $2

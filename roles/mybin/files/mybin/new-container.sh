#!/bin/bash
mkdir -p ${HOME}/fake-home
lxc network set lxdbr0 raw.dnsmasq dhcp-option=6,8.8.8.8,8.8.4.4
lxc launch $1 $2
lxc config device add $2 myhomedir disk source=${HOME}/fake-home path=/home/ubuntu
lxc config set $2 raw.idmap "both 1000 1000"
lxc restart $2
lxc exec $1 --user 0 -- bash -c 'sudo apt update;sudo apt install -y fish zsh'

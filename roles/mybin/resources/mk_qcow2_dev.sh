#! /usr/bin/env bash
sudo modprobe nbd max_part=8
sudo qemu-nbd --connect=/dev/nbd$1 $2
ls /dev/nbd$1*

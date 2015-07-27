#! /usr/bin/env bash
sudo fdisk /dev/nbd$1 -l

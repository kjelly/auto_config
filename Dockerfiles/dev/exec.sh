#!/bin/bash
docker exec -it -w /home/ubuntu -e TERM=xterm-256color -u ubuntu --detach-keys "ctrl-j,j" dev fish

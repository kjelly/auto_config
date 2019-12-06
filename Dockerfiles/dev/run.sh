#!/bin/bash
docker run -d --name dev -v $HOME/nfs:/root/nfs dev:latest

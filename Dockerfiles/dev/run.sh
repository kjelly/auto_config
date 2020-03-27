#!/bin/bash
docker run -d --name dev -v home:/home/ubuntu  -p 6080:80 -p 7000-7100:7000-7100 -v /dev/shm:/dev/shm/ -v /tmp/:/tmp/ -e USER=ubuntu -e PASSWORD=password  dev:latest

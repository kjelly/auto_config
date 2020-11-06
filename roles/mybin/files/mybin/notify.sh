#!/bin/sh

msg=$1
shift
while true; do
  $@ && break
  sleep 1s
done
duration=$SECONDS
echo $duration


hterm-notify.sh $msg

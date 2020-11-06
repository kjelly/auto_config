#!/bin/bash

if syncthing -upgrade-check
then
  sudo systemctl stop syncthing
  sudo syncthing -upgrade
  sudo systemctl start syncthing
  echo 'upgrade'
fi


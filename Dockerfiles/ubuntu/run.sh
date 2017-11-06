#!/bin/bash
docker run --rm -it -v `echo $HOME`/auto_config:/auto_config  auto_config_ubuntu_env /bin/bash

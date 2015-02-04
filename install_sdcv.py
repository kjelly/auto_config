#! /usr/bin/env python
from common.dir_operator import get_home_dir, make_link
import os.path
from os import listdir


os.system("sudo apt-get install sdcv")
os.system("wget http://abloz.com/huzheng/stardict-dic/zh_TW/stardict-langdao-ec-big5-2.4.2.tar.bz2 -O /dev/shm/stardict-langdao-ec-big5-2.4.2.tar.bz2")
os.system("wget http://abloz.com/huzheng/stardict-dic/zh_TW/stardict-langdao-ce-big5-2.4.2.tar.bz2 -O /dev/shm/stardict-langdao-ce-big5-2.4.2.tar.bz2")
os.system("mkdir -p $HOME/.stardict/dic")
os.system("tar jxvf /dev/shm/stardict-langdao-ce-big5-2.4.2.tar.bz2 -C $HOME/.stardict/dic")
os.system("tar jxvf /dev/shm/stardict-langdao-ec-big5-2.4.2.tar.bz2 -C $HOME/.stardict/dic")





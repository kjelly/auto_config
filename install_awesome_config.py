#! /usr/bin/env python
from common.dir_operator import get_home_dir, make_link
import os.path


source = 'awesome/rc.lua'
target = os.path.join(get_home_dir(), '.config', source)

print make_link(source, target)



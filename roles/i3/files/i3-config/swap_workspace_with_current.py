#!/usr/bin/python

import json
from lib import get_active_workspace, get_first_args, swap_workspace

workspace = get_active_workspace()
swap_workspace(workspace['num'], int(get_first_args()))

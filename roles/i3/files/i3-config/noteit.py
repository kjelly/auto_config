#!/usr/bin/env python3
import i3
import os
import subprocess
from os.path import expanduser
from lib import dmenu, dmenu_cmd
import re
import json


def main():
    wid = str([i.get('window') for i in i3.filter(nodes=[]) if i.get('focused')][0])

    home = expanduser("~")
    todo_db_path = os.path.join(home, '.i3_title_todo')
    if os.path.exists(todo_db_path):
        with open(todo_db_path, 'r') as ftr:
            db = json.loads(ftr.read())
    else:
        db = {}

    answer = dmenu(db.get(wid, []), dmenu_cmd('note: ')).strip()

    if answer:
        print(type(wid))
        todo_list = db.get(wid, [])
        print(type(wid))
        if answer not in todo_list:
            todo_list.append(answer)
        print(type(wid))
        db[wid] = todo_list
        with open(todo_db_path, 'w') as ftr:
            ftr.write(json.dumps(db))
        answer = "<span foreground='red'>%s</span>" % wid
        os.system('''i3-msg title_format "<b>%class | %title | {note}</b> " '''.format(note=answer))


if __name__ == '__main__':
    main()

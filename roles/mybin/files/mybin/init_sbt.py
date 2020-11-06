#! /usr/bin/python
from subprocess import check_output
import os
import re
import sys

def main():
    if len(sys.argv) < 1:
        print "You must provide project name."
        return
    project_name = sys.argv[1]
    os.system("git clone https://github.com/ya790206/sbt_project_template %s" % project_name)
    build_sbt = '%s/build.sbt' % project_name
    with open(build_sbt, 'r') as ftr:
        data = ftr.read()
    data = data.replace("project_template", project_name)
    with open(build_sbt, 'w') as ftr:
        ftr.write(data)

    os.system("rm -rf %s/.git" % project_name)

if __name__ == '__main__':
    main()



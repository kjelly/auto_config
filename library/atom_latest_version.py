#!/usr/bin/python
from ansible.module_utils.basic import AnsibleModule
from pyquery import PyQuery as pq


def main():
    module = AnsibleModule(argument_spec={})
    d = pq(url='https://github.com/atom/atom/releases')
    version = d(".label-latest .css-truncate-target").text()
    module.exit_json(changed=False, VERSION=version)


if __name__ == '__main__':
    main()

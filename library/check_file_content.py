#!/usr/bin/python
from ansible.module_utils.basic import *
import re


def main():
    module = AnsibleModule(argument_spec=dict(
        path=dict(type='str', required=True),
        pattern=dict(type='str', required=True),
    ))
    try:
        with open(module.params['path'], 'r') as ftr:
            data = ftr.read()
    except:
        module.exit_json(changed=False, value=False)

    if len(re.findall(module.params['pattern'], data)) != 0:
        module.exit_json(changed=False, value=True)
    module.exit_json(changed=False, value=False)


if __name__ == '__main__':
    main()

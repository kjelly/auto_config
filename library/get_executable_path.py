#!/usr/bin/python
from ansible.module_utils.basic import AnsibleModule
import subprocess


def main():
    module = AnsibleModule(argument_spec=dict(
        name=dict(type='str', required=True),
    ))
    try:
        output = subprocess.check_output(['which', module.params['name']]).strip()
    except Exception as e:
        module.exit_json(changed=False, path='', exist=False, err=e)
    except:
        module.exit_json(changed=False, path='', exist=False, err="Exception happened")
    module.exit_json(changed=False, path=output, exist=True)


if __name__ == '__main__':
    main()

from subprocess import check_output
import os
import sys

def find_screen():
    output = check_output("xrandr|grep ' connected'", shell=True).split('\n')
    ret = {'other': [], 'primary': ''}
    for i in output:
        i = i.strip()
        if len(i) == 0:
            continue
        if 'primary' in i:
            ret['primary'] = i.split()[0]
        else:
            ret['other'].append(i.split()[0])
    return ret



def main():
    place = sys.argv[1]
    screen_info = find_screen()
    os.system('xrandr --output %s --%s-of %s' % (screen_info['other'][0], place, screen_info['primary']))


if __name__ == '__main__':
    main()


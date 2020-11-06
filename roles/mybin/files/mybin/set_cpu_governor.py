#! /usr/bin/env python
import multiprocessing
import os


def set_cpu_governors(policy):
    cpu_count = multiprocessing.cpu_count()
    for i in xrange(cpu_count):
        os.system("sudo cpufreq-set -c %d -g %s" % (i, policy))


def user_choose_governors():
    governors = ['ondemand', 'performance', 'conservative', 'powersave']
    while 1:
        try:
            for i, value in enumerate(governors):
                print ' %d) %s, ' % (i + 1, value),
            print
            index = input("chooose one: ")
            return governors[index - 1]
        except Exception as e:
            print e
            print 'wrong number.'


if __name__ == '__main__':
    import sys
    if len(sys.argv) < 2:
        governor = user_choose_governors()
    else:
        governor = sys.argv[1]
    set_cpu_governors(governor)




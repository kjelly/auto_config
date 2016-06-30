auto_config
===========

The goal of the project is that make me life easy. All of configurations
is managed by Ansible. We don't need to modify configurations manually.

How to use
----------

```
$ git clone https://github.com/ya790206/auto_config
$ cd auto_config
$ ./install-deb-dependency.sh # for ubuntu 16.04. It's needed only once.
$ cp playbook-full.yml pc.yml
$ # modify pc.yml
$ sudo ls # It's needed for installing softwares.
$ ./run.py -p pc.yml -a deploy # install softwares and generate configurations for them
$ ./run.py -p pc.yml -a config # generate configurations only
```


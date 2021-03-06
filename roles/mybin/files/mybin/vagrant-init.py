#!/usr/bin/env python
import os
import sys
import subprocess

template = '''# -*- mode: ruby -*-
# vi: set ft=ruby :

# All Vagrant configuration is done below. The "2" in Vagrant.configure
# configures the configuration version (we support older styles for
# backwards compatibility). Please don't change it unless you know what
# you're doing.
Vagrant.configure(2) do |config|
  config.vm.box = "{box}"
  config.vm.hostname =  Pathname.new(File.dirname(__FILE__)).basename
  config.vm.network :bridged , :mac => "{mac}"
  config.ssh.insert_key = false

  # Disable automatic box update checking. If you disable this, then
  # boxes will only be checked for updates when the user runs
  # `vagrant box outdated`. This is not recommended.
  # config.vm.box_check_update = false

  # Create a forwarded port mapping which allows access to a specific port
  # within the machine from a port on the host machine. In the example below,
  # accessing "localhost:8080" will access port 80 on the guest machine.
  #config.vm.network "forwarded_port", guest: 80, host: 8080

  # Create a private network, which allows host-only access to the machine
  # using a specific IP.
  # config.vm.network "private_network", ip: "192.168.33.10"

  # Create a public network, which generally matched to bridged network.
  # Bridged networks make the machine appear as another physical device on
  # your network.
  # config.vm.network "public_network"

  # Share an additional folder to the guest VM. The first argument is
  # the path on the host to the actual folder. The second argument is
  # the path on the guest to mount the folder. And the optional third
  # argument is a set of non-required options.
  # config.vm.synced_folder "../data", "/vagrant_data"

  # Provider-specific configuration so you can fine-tune various
  # backing providers for Vagrant. These expose provider-specific options.
  # Example for VirtualBox:
  #
  config.vm.provider "virtualbox" do |vb|
    vb.memory = "4096"
    vb.cpus = {cpus}

  end
  config.vm.provision :shell, path: "bootstrap.sh"
end
'''


def main():
    path = os.getcwd()
    box = sys.argv[1]
    cpus = subprocess.check_output('cat /proc/cpuinfo |grep processor|wc -l ', shell=True).strip()
    mac = "52:54:00:%02x:%02x:%02x" % (
                    random.randint(0, 255),
                    random.randint(0, 255),
                    random.randint(0, 255))
    with open(os.path.join(path, 'Vagrantfile'), 'w') as ftr:
        ftr.write(template.format(cpus=cpus, box=box, mac=mac))

    with open(os.path.join(path, 'bootstrap.sh'), 'w') as ftr:
        ftr.write('')


if __name__ == '__main__':
    main()


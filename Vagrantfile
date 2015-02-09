# -*- mode: ruby -*-
# vi: set ft=ruby :

# Vagrantfile API/syntax version. Don't touch unless you know what you're doing!
VAGRANTFILE_API_VERSION = "2"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|

  config.vm.box = "ubuntu/trusty64"
  config.ssh.forward_agent = true
  config.ssh.shell = "bash -c 'BASH_ENV=/etc/profile exec bash'"
  config.vm.provision :shell, path: ".vagrant_bootstrap/bootstrap.sh", privileged: false
  config.vm.provision :shell, run: "always", :path => ".vagrant_scripts/startup.sh", privileged: false

  config.vm.provider "virtualbox" do |vb|
    vb.customize ["modifyvm", :id, "--natdnshostresolver1", "on"]
    vb.customize ["modifyvm", :id, "--memory", "1024"]
    vb.customize ["modifyvm", :id, "--name", "LAMP Box"]
  end

  config.vm.box_check_update = true

  config.vm.network :forwarded_port, guest: 80, host: 8000
  config.vm.network :forwarded_port, guest: 3306, host: 33060

  config.vm.network "private_network", ip: "192.168.56.101"
  config.vm.synced_folder "./www", "/var/www"
  config.vm.synced_folder ".", "/vagrant"

end

# -*- mode: ruby -*-
# vi: set ft=ruby :

IP_NW = "192.168.33."

PGPOOL_NUM = 1
POSTGRESQL_NUM = 2

PGPOOL_IP = 10
POSTGRESQL_IP = 20

Vagrant.configure("2") do |config|

  config.vm.box = "ubuntu/bionic64"
  config.vm.box_check_update = false

  # pgpool
  (1..PGPOOL_NUM).each do |i|
    config.vm.define "pgpool-#{i}" do |node|
      node.vm.provider "virtualbox" do |vb|
        vb.name = "pgpool-#{i}"
        vb.memory = 512
        vb.cpus = 1
      end
      node.vm.hostname = "pgpool-#{i}"
      node.vm.network "private_network", ip: IP_NW + "#{PGPOOL_IP + i}"
      node.vm.network "forwarded_port", guest: 22, host: "#{2510 + i}"

      node.vm.provision "setup-hosts", type: "shell", path: "./script/setup-hosts.sh"
      node.vm.provision "update-dns", type: "shell", path: "./script/update-dns.sh"
    end
  end

  # postgresql
  (1..POSTGRESQL_NUM).each do |i|
    config.vm.define "postgresql-#{i}" do |node|
      node.vm.provider "virtualbox" do |vb|
        vb.name = "postgresql-#{i}"
        vb.memory = 512
        vb.cpus = 1
      end
      node.vm.hostname = "postgresql-#{i}"
      node.vm.network "private_network", ip: IP_NW + "#{POSTGRESQL_IP + i}"
      node.vm.network "forwarded_port", guest: 22, host: "#{2520 + i}"

      node.vm.provision "setup-hosts", type: "shell", path: "./script/setup-hosts.sh"
      node.vm.provision "update-dns", type: "shell", path: "./script/update-dns.sh"
    end
  end
end

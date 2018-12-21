# -*- mode: ruby -*-
# vi: set ft=ruby :

require 'yaml'

inventory_file = ENV['INVENTORY_FILE'] || 'hosts.yml'

inventory = YAML.load_file(inventory_file)
inventory_vars = inventory['all']['vars']
inventory_groups = inventory['all']['children']
  
Vagrant.configure(2) do |config|
  config.vm.box = "ubuntu/xenial64"
  config.vm.box_check_update = false

  config.vm.synced_folder "./vagrant-data/", "/vagrant", type: "rsync"

  # Define and provision master node

  config.vm.define "postgres-n1" do |master|
    h = inventory_groups['master']['hosts']['postgres-n1']
    master.vm.network "private_network", ip: h['ipv4_address']
    master.vm.provider "virtualbox" do |vb|
      vb.name = h['fqdn']
      vb.memory = 764
      vb.customize [ 'storageattach', :id, 
        '--storagectl', 'SCSI Controller', '--port', 2, '--device', 0, '--type', 'hdd',
        '--medium', File.absolute_path("data/postgres-n1/1.vdi")]
    end

    master.vm.provision "setup-database",  type: "ansible" do |ansible|
      ansible.playbook = 'play-database.yml'
      ansible.limit = 'all' # do not limit to master (take standby nodes into play)
      ansible.become = true
      ansible.become_user = 'root'
      ansible.inventory_path = inventory_file
      ansible.verbose = true
    end

  end

  # Define and provision standby nodes

  inventory_groups['standby']['hosts'].keys.each do |machine_name|
    config.vm.define machine_name do |machine|
      h = inventory_groups['standby']['hosts'][machine_name]
      machine.vm.network "private_network", ip: h['ipv4_address']
      machine.vm.provider "virtualbox" do |vb|
         vb.name = h['fqdn']
         vb.memory = 512
         vb.customize [ 'storageattach', :id, 
           '--storagectl', 'SCSI Controller', '--port', 2, '--device', 0, '--type', 'hdd',
           '--medium', File.absolute_path("data/#{machine_name}/1.vdi")]
      end
    end
  end

  # Provision (common)
  
  config.vm.provision "file", source: "keys/id_rsa", destination: ".ssh/id_rsa"
  config.vm.provision "shell", path: "scripts/copy-key.sh", privileged: false

  config.vm.provision "file", source: "files/profile", destination: ".profile"
  config.vm.provision "file", source: "files/bashrc", destination: ".bashrc"

  config.vm.provision "shell", inline: <<-EOD
    apt-get update && apt-get install -y sudo python
  EOD
  
  config.vm.provision "setup-basic", type: "ansible" do |ansible| 
    ansible.playbook = 'play-basic.yml'
    ansible.become = true
    ansible.become_user = 'root'
    ansible.inventory_path = inventory_file
    ansible.verbose = true
  end
  
  config.vm.provision "setup-data-partition", type: "ansible" do |ansible| 
    ansible.playbook = 'play-data-partition.yml'
    ansible.become = true
    ansible.become_user = 'root'
    ansible.inventory_path = inventory_file
    ansible.verbose = true
  end

end

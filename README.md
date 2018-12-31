# README

## 0. Prerequisites ##

### 0.1 Ansible Environment ###

You must install `Ansible` on the control machine, preferably in a virtual Python environment:

    virtualenv pyenv
    . pyenv/bin/activate
    pip install ansible==2.5 netaddr

### 0.2 Provide SSH keys ###

Place your PEM-formatted private key under `keys/id_rsa` and corresponding public key under `keys/id_rsa.pub`. 
Ensure that private key has proper permissions (`0600`).  

### 0.3 Create disk storage

Run the (local) ansible playbook to create all needed VDI disk images:

    ansible-playbook -v -i hosts.yml prepare-disk-images.yml

Verify images are created. For example:

    vboxmanage showmediuminfo disk $PWD/data/postgres-n1/1.vdi

## 1. Prepare inventory file ##

An single inventory file should be created at `hosts.yml`. Both `vagrant` and `ansible` will use this same inventory.
An example inventory file can be found [here](hosts.yml.example).

Also, group variables under `group_vars` must be configured. See `group_vars/*.yml.example` files for available options.

## 2.1 Setup with Vagrant and Ansible ##

If we want a full Vagrant environment (of course we will also need `vagrant` installed), setup the machines and provision in multiple phases.
All phases, apart from the initial `vagrant up`, delegate their work to Ansible playbooks.

First, create some needed directories for secrets and temporary data:

    mkdir -p files/secrets vagrant-data

Setup machines (networking, ansible prerequisites):

    vagrant up --provision-with=shell,file
    
Provision in several phases:
    
    vagrant provision --provision-with=setup-basic
    vagrant provision --provision-with=setup-data-partition
    vagrant provision --provision-with=setup-database
    vagrant provision --provision-with=setup-balancer

## 2.2 Setup with Ansible only ##

If the target machines (either virtual or physical) are already setup and networked (usually in a private network),
then we can directly play the Ansible playbooks:

    ansible-playbook --become --become-user root play-basic.yml
    ansible-playbook --become --become-user root [-e data_partition=/dev/sdc1] play-data-partition.yml
    ansible-playbook --become --become-user root play-database.yml
    ansible-playbook --become --become-user root play-balancer.yml

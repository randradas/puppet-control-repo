# -*- mode: ruby -*-
# vi: set ft=ruby :
#
# All Vagrant configuration is done below. The "2" in Vagrant.configure
# configures the configuration version (we support older styles for
# backwards compatibility). Please don't change it unless you know what
# you're doing.
Vagrant.require_version ">= 1.7.4"
VAGRANTFILE_API_VERSION = "2"
require 'yaml'


# read boxes configuration
cfg_file = YAML.load_file('vagrant.yaml')
boxes = cfg_file['boxes']
domain = cfg_file['domain']
nodes = cfg_file['nodes']


# Convert keys to symbols, useful to pass options to vagrant methods
def keys_to_symbols(hash)
  hash = hash.inject({}){|memo,(k,v)| memo[k.to_sym] = v; memo}
end


# Every Vagrant development environment requires a box. You can search for
# boxes at https://atlas.hashicorp.com/search.
def configure_basic_info(instance, node, boxes, domain)
  box_name = node['box_name']
  instance.vm.box = box_name
  instance.vm.box_url = boxes[box_name]
  instance.vm.hostname = node['hostname'] + '.' + domain

  # configure available resources
  # ioapic is required for 64 bit architecture guest machines
  instance.vm.provider 'virtualbox' do |provider|
    provider.customize [ 'modifyvm', :id, '--memory', node['memory'] ]
    provider.customize [ 'modifyvm', :id, '--cpus', node['cpus'] ]
    provider.customize [ 'modifyvm', :id, '--ioapic', 'on' ]
    provider.customize [ 'modifyvm', :id, '--natdnshostresolver1', 'on' ]
  end
end


# Create networks
def configure_networks(instance, node)
  networks = node['networks']
  networks && networks.each do |network|
    network.each do |network_identifier, network_params|
      if network_params
        network_params = keys_to_symbols(network_params)
        instance.vm.network network_identifier, network_params
      else
        instance.vm.network network_identifier
      end
    end
  end
end


# Create forwarded ports
def configure_forwarded_ports(instance, node)
  forwarded_ports = node['forwarded_ports']
  forwarded_ports && forwarded_ports.each do |forwarded_port|
    forwarded_port = keys_to_symbols(forwarded_port)
    instance.vm.network 'forwarded_port', forwarded_port
  end
end


# Configure synced folders
def configure_synced_folders(instance, node)
  # default synced_folder
  instance.vm.synced_folder ".", "/vagrant"

  # yaml synced_folders
  synced_folders = node['synced_folders']
  synced_folders && synced_folders.each do |synced_folder|
    instance.vm.synced_folder synced_folder['host'], synced_folder['guest']
  end
end


# Configure provisioners
def configure_provisioners(instance, node)
  provisioners = node['provisioners']
  provisioners && provisioners.each do |provisioner|
    provisioner.each do |provisioner_type, provisioner_params|
      if provisioner_params
        provisioner_params = keys_to_symbols(provisioner_params)
        instance.vm.provision provisioner_type, provisioner_params
      end
    end
  end

  #instance.vm.provision 'puppet' do |puppet|
  #  puppet.working_path = '/vagrant/'
  #  puppet.hiera_config_path = 'hiera.yaml'
  #  puppet.module_path = 'modules'
  #  puppet.manifest_path = 'manifests'
  #  puppet.manifest_file = 'site.pp'
  #  puppet.options = '--verbose --debug'
  #end
end


# Configure providers
def configure_providers(instance, node)
  # configure specific provider options
  providers = node['providers']
  providers && providers.each do |provider|
    provider.each do |provider_type, provider_params|
      if provider_params
        provider_params = keys_to_symbols(provider_params)
        instance.vm.provider provider_type, provider_params
      end
    end
  end
end


# Create boxes
Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  nodes.each do |node|
    config.vm.define node['hostname'] do |instance|
      # if plugin vagrant cachier
      # if plugin vbguest
      configure_basic_info(instance, node, boxes, domain)
      configure_networks(instance, node)
      configure_forwarded_ports(instance, node)
      configure_synced_folders(instance, node)
      configure_provisioners(instance, node)
      configure_providers(instance, node)
    end
  end
end

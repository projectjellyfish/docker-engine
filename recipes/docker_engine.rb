#
# Cookbook Name:: docker_engine
# Recipe:: default
#
# Copyright (c) 2015 The Authors, All Rights Reserved.
include_recipe 'yum-docker'


# Make sure that the key.json file is deleted (happens if it is a clone machine with Docker)
file '/etc/docker/key.json' do
  ignore_failure true
  only_if { File.exists?('/etc/docker/key.json') }
  action :delete
end

# Add the Docker repo to Yum
# Removed in favor of the docker-yum cookbook
#yum_repository 'docker-engine' do
#  description "Docker Repository"
#  baseurl 'https://yum.dockerproject.org/repo/main/centos/7'
#  gpgkey 'https://yum.dockerproject.org/gpg'
#  action :create
#end

# Install Docker Engine
# Removed in favor of docker_installation_package LWRP
#package 'docker-engine' do
#  version node['docker_engine_version']
#end

# Install Docker Engine
docker_installation_package 'default' do
  version node['docker_engine_version']
  action :create
end


# Start the Docker Service
# Chris K (2/16/2016) - This is not up to date with Docker Engine 1.10.1, if using 1.10.1+
# we will need to wait for the docker cookbook to get updated or use the enable_docker_engine 
# AND start_docker_engine
docker_service 'default' do
  log_opts 'max-size=100m'
  exec_opts 'native.cgroupdriver=cgroupfs'
  storage_driver 'overlay'
  action [:create, :start]
end

#execute 'enable_docker_engine' do
#  command "systemctl enable docker.service"
#end

#execute 'start_docker_engine' do
#  command "systemctl start docker.service"
#end


# Login to Docker Trusted Registery
# @todo need to change this to use attribues and the DTR
docker_registry 'https://index.docker.io/v1/' do
  username node['dockerhost']['docker_hub_user']
  password node['dockerhost']['docker_hub_pass']
  email node['dockerhost']['docker_hub_email']
end

# Pull down the UCP image (since we need this no matter what)
docker_image 'docker/ucp' do
  tag node['docker_ucp_version']
  action :pull_if_missing
end

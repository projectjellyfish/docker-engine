#
# Cookbook Name:: docker_engine
# Recipe:: default
#
# Copyright (c) 2015 The Authors, All Rights Reserved.

execute 'create_swarm_master' do
  command "docker run --log-opt max-size=10m --log-opt max-file=5 --rm -i -v /var/run/docker.sock:/var/run/docker.sock --name ucp docker/ucp:#{node['docker_ucp_version']} install --fresh-install"
  not_if 'docker images |grep ucp'
end

# If this is a master server, then let's pull the additional containers we will need

# @todo we need to see if we need to update the containers and if we do, we need to
# kill the containers and restart, see:
# http://stackoverflow.com/questions/26734402/how-to-upgrade-docker-container-after-its-image-changed

# Pull down the Jenkins image
docker_image 'jenkins' do
  tag node['docker_jenkins_version']
  action :pull_if_missing
end

# Pull Down ELK Image
# @todo need ELK container to use
docker_image 'sebp/elk' do
  tag node['docker_elk_version']
  action :pull_if_missing
end

# Pull Down Zabbix Image
# @todo need Zabbix container to use
docker_image 'zabbix/zabbix-server-2.4' do
  tag node['docker_zabbix_version']
  action :pull_if_missing
end

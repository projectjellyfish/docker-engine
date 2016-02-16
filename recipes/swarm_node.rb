#
# Cookbook Name:: docker_engine
# Recipe:: default
#
# Copyright (c) 2015 The Authors, All Rights Reserved.

execute 'create_swarm_node' do
  command "docker run --log-opt max-size=10m --log-opt max-file=5 -e UCP_ADMIN_USER=#{node['dockerhost']['master_adminuser']} -e UCP_ADMIN_PASSWORD=#{node['dockerhost']['master_adminpass']} --rm -i -v /var/run/docker.sock:/var/run/docker.sock --name ucp docker/ucp:#{node['docker_ucp_version']} join --fresh-install --url https://#{node['dockerhost']['master_ip']} --fingerprint=#{node['dockerhost']['master_fingerprint']}"
  not_if 'docker images |grep ucp'
end